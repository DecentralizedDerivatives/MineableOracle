import web3,json
from web3 import Web3
import requests,json, time,random
import pandas as pd
import hashlib
from Naked.toolshed.shell import execute_js, muterun_js, run_js
from multiprocessing import Process, freeze_support

contract_address = "";
node_url ="http://localhost:8545" #https://rinkeby.infura.io/
net_id = 60 #eth network ID
last_block = 0

public_keys = ["0xe037ec8ec9ec423826750853899394de7f024fee","0xcdd8fa31af8475574b8909f135d510579a8087d3","0xb9dd5afd86547df817da2d0fb89334a6f8edd891","0x230570cd052f40e14c14a81038c6f3aa685d712b","0x3233afa02644ccd048587f8ba6e99b3c00a34dcc"]
private_keys = ["4bdc16637633fa4b4854670fbb83fa254756798009f52a1d3add27fb5f5a8e16","d32132133e03be292495035cf32e0e2ce0227728ff7ec4ef5d47ec95097ceeed","d13dc98a245bd29193d5b41203a1d3a4ae564257d60e00d6f68d120ef6b796c5","4beaa6653cdcacc36e3c400ce286f2aefd59e2642c2f7f29804708a434dd7dbe","78c1c7e40057ea22a36a0185380ce04ba4f333919d1c5e2effaf0ae8d6431f14"]

static_jazz1 = "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000"
static_jazz2 = "00000000000000000000000000000000000000000000000000000000000000386a736f6e2868747470733a2f2f6170692e676461782e636f6d2f70726f64756374732f4254432d5553442f7469636b6572292e70726963650000000000000000"

def generate_random_number():
    return str(random.randint(1000000,9999999))

def mine(challenge, public_address, difficulty):
	x = 0;
	while True:
		x += 1;
		nonce = Web3.toHex(str.encode(str(generate_random_number())))
		_string = str(challenge[1:]).strip() + public_address[2:].strip() + nonce[2:].strip()
		_solution = Web3.toHex(Web3.sha3(text=_string.strip()))
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
	challenge,difficulty,apiString = getVariables();
	while True:
		nonce = mine(str(challenge),public_keys[miners_started],difficulty);
		if(nonce > 0):
			print ("You guessed the hash!");
			value = getAPIvalue() - miners_started*10; #account 2 should always be winner
			arg_string =""+ str(nonce) + " "+str(value)+" "+str(contract_address)+" "+str(public_keys[miners_started])+" "+str(private_keys[miners_started])
			run_js('testSubmitter.js',arg_string);
			miners_started += 1
			if(miners_started == 5):
				v = False;
				getAddress();
				while(v == False):
					_challenge,difficulty = getVariables();
					if challenge == _challenge:
						v = False
						time.sleep(10);
					else:
						v = True
						challenge = _challenge;
				miners_started = 0;
		else:
			pass 
	print('Miner Stopping')

def getVariables():
	getAddress();
	print (contract_address)
	payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_call","params":[{"to":contract_address,"data":"0x94aef022"}, "latest"]}
	r = requests.post(node_url, data=json.dumps(payload));
	val = jsonParser(r);
	val = val['result'];
	print('val',val);
	_challenge = val[:66]
	val = val[66:]
	_apiId = int(val[:64])
	val = val[64:]
	_difficulty = int(val[:64]);
	val = val[64:]
	print(_challenge)
	print(_apiId)
	print(_difficulty)
	print(val)
	_apiString = web3.toAscii(val)
	print(_apiString)
	return _challenge,_apiId,_difficulty,_apiString

def jsonParser(_info):
	my_json = _info.content
	data = json.loads(my_json)
	s = json.dumps(data, indent=4, sort_keys=True)
	return json.loads(s)

def getAddress():
	global last_block, contract_address
	payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_blockNumber"}
	r = requests.post(node_url, data=json.dumps(payload));
	d = jsonParser(r);
	block = int(d['result'],16)
	while(block > last_block):
		print('block',block);
		try:
			payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_getTransactionByBlockNumberAndIndex","params":[hex(block),0]}
			r = requests.post(node_url, data=json.dumps(payload));
			d = jsonParser(r);
			tx = d['result']
			payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_getTransactionReceipt","params":[tx['hash']]}
			r = requests.post(node_url, data=json.dumps(payload));
			d = jsonParser(r);
			tx = d['result']
			contract_address =tx['contractAddress']
			print (len(contract_address))
			if len(contract_address)>0:
				last_block = block 
				block = 0;
				print('New Contract Address',contract_address)
				return True;
		except:
			pass
		block = block - 1;
	return False;

def bytes2int(str):
 return int(str.encode('hex'), 32)

def bytes_to_int(bytes):
    result = 0

    for b in bytes:
        result = result * 256 + int(b)

    return result


# def testHash():
# 	_solutions = '0xbc756c25d68ea2f260ea5f15e1e1c734c019cbc014270dd386eacca4699f60f6';
# 	v = Web3.toHex(Web3.sha3(hexstr=_solutions))
# 	x = "0x" + hashlib.new('sha256',bytes.fromhex(_solutions[2:])).hexdigest()
# 	z= Web3.toHex(Web3.sha3(hexstr=(hashlib.new('ripemd160',bytes.fromhex(_solutions[2:])).hexdigest())));
# 	print("v",v)
# 	print("x",x);
# 	print("z",z);


#testHash();
#working()
getVariables()
#masterMiner();
#runInParallel(masterMiner,masterMiner,masterMiner,masterMiner,masterMiner)

#getAddress();