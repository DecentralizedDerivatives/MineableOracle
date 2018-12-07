import web3,json
from web3 import Web3
import requests,json, time,random
import pandas as pd
import hashlib
from Naked.toolshed.shell import execute_js, muterun_js, run_js

contract_addresses = ["0x72689F0E911adF8fc41200F0fb112D2D5472c6C3","0x00285C75fa033EBAd57f2267aEBF73db1f2Aae45"];#1day and 10 min
node_url ="https://rinkeby.infura.io/"
net_id = 4 #eth network ID
last_block = 0

public_keys = ["0xe010ac6e0248790e08f42d5f697160dedf97e024","0xcdd8fa31af8475574b8909f135d510579a8087d3","0xb9dd5afd86547df817da2d0fb89334a6f8edd891","0x230570cd052f40e14c14a81038c6f3aa685d712b","0x3233afa02644ccd048587f8ba6e99b3c00a34dcc"]
private_keys = ["3a10b4bc1258e8bfefb95b498fb8c0f0cd6964a811eabca87df5630bcacd7216","d32132133e03be292495035cf32e0e2ce0227728ff7ec4ef5d47ec95097ceeed","d13dc98a245bd29193d5b41203a1d3a4ae564257d60e00d6f68d120ef6b796c5","4beaa6653cdcacc36e3c400ce286f2aefd59e2642c2f7f29804708a434dd7dbe","78c1c7e40057ea22a36a0185380ce04ba4f333919d1c5e2effaf0ae8d6431f14"]

def generate_random_number():
    return str(random.randint(1000000,9999999))

def mine(challenge, public_address, difficulty):
	x = 0;
	while True:
		x += 1;
		nonce = Web3.toHex(str.encode(str(generate_random_number())))
		_string = str(challenge[1:]).strip() + public_address[2:].strip() + nonce[2:].strip()
		_solution = Web3.toHex(Web3.sha3(text=_string.strip()))
		rem = ( int(_solution,16) % 3)
		if(rem == 2):
			n = Web3.toHex(Web3.sha3(hexstr=_solution))
		elif(rem == 1):
			n = "0x" + hashlib.new('sha256',bytes.fromhex(_solution[2:])).hexdigest()
		else:
			n = Web3.toHex(Web3.sha3(hexstr=(hashlib.new('ripemd160',bytes.fromhex(_solution[2:])).hexdigest())));
		print("n",n)
		hash1 = int(n,16)
		if hash1 % difficulty == 0:
			return int(nonce,16);
		if x % 10000 == 0:
			payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_blockNumber"}
			r = requests.post(node_url, data=json.dumps(payload));
			d = jsonParser(r);
			last_block = int(d['result'],16)
			_challenge,_difficulty,v = getVariables();
			if (v == True):
				return 0;

def getAPIvalue():
	url = "https://api.gdax.com/products/BTC-USD/ticker"
	response = requests.request("GET", url)
	price =response.json()['price']
	return int(float(price))

def masterMiner():
	miners_started = 0
	for contract_address in contract_addresses:
		x=0
		print('c',contract_address);
		challenge,difficulty = getVariables(contract_address);
		while True and x < 1:
			nonce = mine(str(challenge),public_keys[miners_started],difficulty);
			if(nonce > 0):
				print ("You guessed the hash!");
				value = getAPIvalue() - miners_started*10; #account 2 should always be winner
				arg_string =""+ str(nonce) + " "+str(value)+" "+str(contract_address)+" "+str(public_keys[miners_started])+" "+str(private_keys[miners_started])
				run_js('submitter.js',arg_string);
				miners_started += 1
				if(miners_started == 5):
					#challenge,difficulty = getVariables(contract_address);
					miners_started = 0;
					x += 1;
			else:
				pass
	print('Miner Stopping')

def getVariables(contract_address):
	payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_call","params":[{"to":contract_address,"data":"0x94aef022"}, "latest"]}
	r = requests.post(node_url, data=json.dumps(payload));
	val = r.content
	val2 = val[102:]
	val2 = val2[:-2]
	_challenge = val[34:101].decode("utf-8")
	val3 = bytes.decode(val2)
	_difficulty = int(val3);
	return _challenge,_difficulty;

def jsonParser(_info):
	my_json = _info.content
	data = json.loads(my_json)
	s = json.dumps(data, indent=4, sort_keys=True)
	return json.loads(s)

#working()
#getVariables()
masterMiner();
#runInParallel(masterMiner,masterMiner,masterMiner,masterMiner,masterMiner)

#getAddress();
