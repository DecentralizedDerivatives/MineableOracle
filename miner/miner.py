
# coding: utf-8

# In[9]:

import web3
from web3 import Web3
import requests,json, time,random
import pandas as pd
from Naked.toolshed.shell import execute_js, muterun_js, run_js

public_address = "0xb204edaf0410675e00e6c8a7e448a9e8e2db69aa";
private_key = "fe5f52e7e0381448fe7d4a99e409b6da987b31362125ccb7bca781949cf61710";
contract_address =  "0x5f6554749e44f166445d08d51aa05b9cff64d1b0"
node_url ="http://localhost:8545" #https://rinkeby.infura.io/
net_id = 60 #eth network ID


def generate_random_number():
    return str(random.randint(1000000,9999999))

# difficulty is an int 


def mine(challenge, public_address, difficulty):
	x = 0;
	while True:
		x += 1;
		nonce = generate_random_number()
		print (str(challenge))
		_string = challenge + public_address[2:] + Web3.toHex(str.encode(str(nonce)))[2:]
		print (_string)
		n = Web3.sha3(_string)
		hash1 = int(n,16)
		print ('Hash: ',hash1,'Difficulty: ',difficulty,'Nonce: ',nonce)
		if hash1 % difficulty == 0:
			print ('SUCESSS!!')
			return int(nonce);
		if x % 10000 == 0:
			_challenge,_difficulty = getVariables();
			if _challenge == challenge:
				pass;
			else:
				return 0;

def getAPIvalue():
	url = "https://api.gdax.com/products/BTC-USD/ticker"
	response = requests.request("GET", url)
	price =response.json()['price']
	return int(float(price))

def masterMiner():
	while True:
		challenge,difficulty = getVariables();
		print(challenge,difficulty);
		nonce = mine(challenge,public_address[2:],difficulty);
		print(nonce);
		if(nonce > 0):
			print ("You guessed the hash");
			value = getAPIvalue();
			arg_string =""+ str(nonce) + " "+str(value)+" "+str(contract_address)+" "+str(public_address)
			run_js('submitter.js',arg_string);
			time.sleep(30)
		else:
			pass

def getVariables():
	payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_call","params":[{"to":contract_address,"data":"0x94aef022"}, "latest"]}
	r = requests.post(node_url, data=json.dumps(payload));
	val = r.content
	val2 = val[100:]
	val2 = val2[:-3]
	_challenge = val[34:98].decode("utf-8")
	val3 = bytes.decode(val2)
	_difficulty = int(val3);
	return _challenge,_difficulty;

def bytes2int(str):
 return int(str.encode('hex'), 32)

def bytes_to_int(bytes):
    result = 0

    for b in bytes:
        result = result * 256 + int(b)

    return result



masterMiner();

def testHash():
	challenge = "0x6ea5c1031c390399bdeeef830f5ad748eba64ff30dfefdd1778ba9ba371478e3";
	nonce = Web3.toHex(str.encode(str(330608)));
	p = "0xca35b7d915458ef540ade6068dfe2f44e8fa733c";
	string = challenge + p[2:]+ nonce[2:];
	print(string);
	n = Web3.sha3(string)
	n_int = int(n,16)
	print('n: ',n);
	print('n_int: ', n_int);


def working():
	challenge = "0x6ea5c1031c390399bdeeef830f5ad748eba64ff30dfefdd1778ba9ba371478e3";
	nonce = Web3.toHex(str.encode(str(330608)));
	p = "0xca35b7d915458ef540ade6068dfe2f44e8fa733c";
	string = challenge + p[2:]+ nonce[2:];
	print(string);
	n = Web3.sha3(string)
	n_int = int(n,16)
	print('n: ',n);
	print('n_int: ', n_int);