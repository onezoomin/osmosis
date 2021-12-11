#!/bin/bash

exit_with_error()
{
  echo "$1" 1>&2
  exit 1
}

KeyringBackend=test
Chain=test

# Get the options
while getopts ":kc:" option; do
   case $option in
      k) # Keyring backend
         KeyringBackend=$OPTARG;;
      c) # Enter a name
         Chain=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit 1
   esac
done

# Make sure the path is set correctly
export PATH=~/go/bin:$PATH

echo "osmosisd Version: `osmosisd version`"

osmosisd keys show validator --keyring-backend ${KeyringBackend} || osmosisd keys add validator --keyring-backend ${KeyringBackend} || exit_with_error "Error: Validator add failed"
osmosisd keys show delegator --keyring-backend ${KeyringBackend} || osmosisd keys add delegator --keyring-backend ${KeyringBackend} || exit_with_error "Error: Delegator add failed"
osmosisd init node --chain-id ${Chain} || exit_with_error "Error: Could not init node"

# Change the staking token to uosmo
# Note: sed works differently on different platforms
echo "Updating your staking token to uosmo in the genesis file..."
OS=`uname`
if [[ $OS == "Linux"* ]]; then
    echo "Your OS is a Linux variant..."
    sed -i "s/stake/uosmo/g" ~/.osmosisd/config/genesis.json || exit_with_error "Error: Could not update staking token"
elif [[ $OS == "Darwin"* ]]; then
    echo "Your OS is Mac OS/darwin..."
    sed -i "" "s/stake/uosmo/g" ~/.osmosisd/config/genesis.json || exit_with_error "Error: Could not update staking token"
else
    # Dunno
    echo "Your OS is not supported"
    exit 1
fi

echo "Adding validator to genesis.json..."
osmosisd add-genesis-account validator 5000000000uosmo --keyring-backend ${KeyringBackend} || exit_with_error "Error: Could not add validator to genesis"

echo "Adding delegator to genesis.json..."
osmosisd add-genesis-account delegator 2000000000uosmo --keyring-backend ${KeyringBackend} || exit_with_error "Error: Could not add delegator to genesis"
echo "Creating genesis transaction..."
osmosisd gentx validator 1000000uosmo --chain-id ${Chain} --keyring-backend ${KeyringBackend} || exit_with_error "Error: Genesis transaction failed"

echo "Adding genesis transaction to genesis.json..."
osmosisd collect-gentxs || exit_with_error "Error: Could not add transaction to genesis"

echo "If there were no errors above, you can now type 'osmosisd start' to start your node"
