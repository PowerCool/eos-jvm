#!/bin/sh

alias cleos='docker exec -it nodeos /opt/eosio/bin/cleos -u http://nodeosd:8888 --wallet-url http://keosd:8899'

# create a key pair
declare CREATE_KEY_RESULT=($(cleos create key --to-console))
PRIVATE_KEY=${CREATE_KEY_RESULT[2]}
PUBLIC_KEY=${CREATE_KEY_RESULT[5]}

## create the default wallet
declare CREATE_WALLET_RESULT=($(cleos wallet create --to-console))
WALLET_PASSWORD=${CREATE_WALLET_RESULT[22]}

## import the `signature-provider` private key into the default wallet
cleos wallet import --private-key 5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3

## import the key into the default wallet
cleos wallet import --private-key $PRIVATE_KEY

## install the eosio.bios contract
cleos set contract eosio /contracts/eosio.bios -p eosio@active

## show the accounts by public key to verify they were created
cleos get accounts $PUBLIC_KEY

## create various accounts required by the system
declare CREATE_TEMP_KEY_RESULT=($(cleos create key --to-console))
TEMP_PRIVATE_KEY=${CREATE_TEMP_KEY_RESULT[2]}
TEMP_PUBLIC_KEY=${CREATE_TEMP_KEY_RESULT[5]}
cleos wallet import $TEMP_PRIVATE_KEY
cleos create account eosio eosio.bpay $TEMP_PUBLIC_KEY $TEMP_PUBLIC_KEY

cleos create account eosio eosio.names $PUBLIC_KEY $PUBLIC_KEY
cleos create account eosio eosio.ram $PUBLIC_KEY $PUBLIC_KEY
cleos create account eosio eosio.ramfee $PUBLIC_KEY $PUBLIC_KEY
cleos create account eosio eosio.saving $PUBLIC_KEY $PUBLIC_KEY
cleos create account eosio eosio.stake $PUBLIC_KEY $PUBLIC_KEY
cleos create account eosio eosio.vpay $PUBLIC_KEY $PUBLIC_KEY

## create an account for and install the eosio.token contract
cleos create account eosio eosio.token \
        $PUBLIC_KEY \
        $PUBLIC_KEY
cleos set contract eosio.token contracts/eosio.token -p eosio.token@active

## create an account for and install the exchange contract
cleos create account eosio exchange  \
        $PUBLIC_KEY \
        $PUBLIC_KEY
cleos set contract exchange contracts/exchange -p exchange@active

## create an account for and install the msig contracts
cleos create account eosio eosio.msig \
        $PUBLIC_KEY \
        $PUBLIC_KEY
cleos set contract eosio.msig contracts/eosio.msig -p eosio.msig@active

## create an account using the signature authority
cleos create account eosio sigaccount EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

## create the circulating supply of SYS tokens
cleos push action eosio.token create '[ "eosio", "1200000.0000 SYS"]' \
         -p eosio.token@active

## allocate some SYS tokens to the eosio account
cleos push action eosio.token issue '[ "eosio", "200000.0000 SYS", "eosio_init" ]' \
        -p eosio@active

## Install the system contracts
cleos set contract eosio /contracts/eosio.system -p eosio@active

## Make eosio.msg a privileged account so that it can authorize on behalf of eosio
cleos push action eosio setpriv '["eosio.msig", 1]' -p eosio@active

## Create an account for the block producer
cleos system newaccount eosio --transfer memtripblock $PUBLIC_KEY --stake-net "100.0000 SYS" --stake-cpu "100.0000 SYS" --buy-ram "100.0000 SYS"
cleos push action eosio.token issue '[ "memtripblock", "100.0000 SYS", "eosio_init" ]' \
        -p eosio@active

## Register the public key and account as a block producer
cleos system regproducer memtripblock $PUBLIC_KEY https://memtrip.com/

##
## create a key pair for multisig accounts
##
declare MULTISIG_CREATE_KEY_RESULT=($(cleos create key --to-console))
MULTISIG_PRIVATE_KEY=${MULTISIG_CREATE_KEY_RESULT[2]}
MULTISIG_PUBLIC_KEY=${MULTISIG_CREATE_KEY_RESULT[5]}

cleos wallet import --private-key $MULTISIG_PRIVATE_KEY

## The multisig account
cleos system newaccount eosio --transfer memtripmulti $MULTISIG_PUBLIC_KEY --stake-net "500.0000 SYS" --stake-cpu "500.0000 SYS" --buy-ram "500.0000 SYS"
cleos push action eosio.token issue '[ "memtripmulti", "500.0000 SYS", "eosio_init" ]' \
        -p eosio@active

## Create 1/3 signatories
cleos system newaccount eosio --transfer memtrip11111 $MULTISIG_PUBLIC_KEY --stake-net "111.0000 SYS" --stake-cpu "111.0000 SYS" --buy-ram "111.0000 SYS"
cleos push action eosio.token issue '[ "memtrip11111", "100.0000 SYS", "eosio_init" ]' \
        -p eosio@active

## Create 2/3 signatories
cleos system newaccount eosio --transfer memtrip22222 $MULTISIG_PUBLIC_KEY --stake-net "222.0000 SYS" --stake-cpu "222.0000 SYS" --buy-ram "222.0000 SYS"
cleos push action eosio.token issue '[ "memtrip22222", "100.0000 SYS", "eosio_init" ]' \
        -p eosio@active

# Create 3/3 signatories
cleos system newaccount eosio --transfer memtrip33333 $MULTISIG_PUBLIC_KEY --stake-net "333.0000 SYS" --stake-cpu "333.0000 SYS" --buy-ram "333.0000 SYS"
cleos push action eosio.token issue '[ "memtrip33333", "100.0000 SYS", "eosio_init" ]' \
        -p eosio@active

cleos set account permission memtripmulti owner \
'{"threshold":2,"keys":[],"accounts":[{"permission":{"actor":"memtrip11111","permission":"owner"},"weight":1},{"permission":{"actor":"memtrip22222","permission":"owner"},"weight":1},{"permission":{"actor":"memtrip33333","permission":"owner"},"weight":1}],"waits":[]}' -p memtripmulti@owner

##
## create a key pair for memtripissue
##
MEMTRIP_ISSUE_PRIVATE_KEY=5JKonnU5r895a1r9iSBRbAxo2CeuCDfNCNnJtUN6tuGWoXp49mg
MEMTRIP_ISSUE_PUBLIC_KEY=EOS6c1rBVtgaMRfb7m173kbkqFXXuLoaQepBXHxFiB5hHaCobZ9CE

cleos wallet import --private-key $MEMTRIP_ISSUE_PRIVATE_KEY

cleos system newaccount eosio --transfer memtripissue $MEMTRIP_ISSUE_PUBLIC_KEY --stake-net "100.0000 SYS" --stake-cpu "100.0000 SYS" --buy-ram "100.0000 SYS"
cleos push action eosio.token issue '[ "memtripissue", "750000.0000 SYS", "eosio_init" ]' \
        -p eosio@active

cleos system newaccount eosio --transfer memtripadmin $MEMTRIP_ISSUE_PUBLIC_KEY --stake-net "100.0000 SYS" --stake-cpu "100.0000 SYS" --buy-ram "100.0000 SYS"
cleos push action eosio.token issue '[ "memtripadmin", "10.0000 SYS", "eosio_init" ]' \
        -p eosio@active

cleos system newaccount eosio --transfer memtripproxy $MEMTRIP_ISSUE_PUBLIC_KEY --stake-net "100.0000 SYS" --stake-cpu "100.0000 SYS" --buy-ram "100.0000 SYS"
cleos push action eosio.token issue '[ "memtripproxy", "10.0000 SYS", "eosio_init" ]' \
        -p eosio@active

# delegate 100% of memtripissue issue tokens to bandwidth for voting, to activate the chain.
# (at least 15% of all tokens participate in voting)
cleos system delegatebw memtripissue memtripissue "200000.0000 SYS" "200000.0000 SYS"
cleos system delegatebw memtripissue memtripproxy "100000.0000 SYS" "100000.0000 SYS"

# vote for memtripblock as the block producer
cleos system voteproducer prods memtripissue memtripblock

cleos system regproxy memtripproxy

## echo the wallet and key details for the developer to take note of
echo "\n"
echo "> system contracts installed"

mkdir -p session/memtripissue
mkdir -p session/multisig
echo $PUBLIC_KEY > session/public_key
echo $PRIVATE_KEY > session/private_key
echo $WALLET_PASSWORD > session/wallet_password
echo $MEMTRIP_ISSUE_PUBLIC_KEY > session/memtripissue/public_key
echo $MEMTRIP_ISSUE_PRIVATE_KEY > session/memtripissue/private_key
echo $MULTISIG_PUBLIC_KEY > session/multisig/public_key
echo $MULTISIG_PRIVATE_KEY > session/multisig/private_key
