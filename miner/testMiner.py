import web3,json
from web3 import Web3
import requests,json, time,random
import pandas as pd
from Naked.toolshed.shell import execute_js, muterun_js, run_js
from multiprocessing import Process, freeze_support

contract_address = "";
node_url ="http://localhost:8545" #https://rinkeby.infura.io/
net_id = 60 #eth network ID
miners_started = 0
last_block = 0

public_keys = ["0xe010ac6e0248790e08f42d5f697160dedf97e024","0xcdd8fa31af8475574b8909f135d510579a8087d3","0xb9dd5afd86547df817da2d0fb89334a6f8edd891","0x230570cd052f40e14c14a81038c6f3aa685d712b","0x3233afa02644ccd048587f8ba6e99b3c00a34dcc"]
private_keys = ["3a10b4bc1258e8bfefb95b498fb8c0f0cd6964a811eabca87df5630bcacd7216","d32132133e03be292495035cf32e0e2ce0227728ff7ec4ef5d47ec95097ceeed","d13dc98a245bd29193d5b41203a1d3a4ae564257d60e00d6f68d120ef6b796c5","4beaa6653cdcacc36e3c400ce286f2aefd59e2642c2f7f29804708a434dd7dbe","78c1c7e40057ea22a36a0185380ce04ba4f333919d1c5e2effaf0ae8d6431f14"]

static_jazz1 = "0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000"
static_jazz2 = "80000000000000000000000000000000000000000000000000000000000000000"

def generate_random_number():
    return str(random.randint(1000000,9999999))

def mine(challenge, public_address, difficulty):
	x = 0;
	while True:
		x += 1;
		nonce = generate_random_number()
		print (str(challenge))
		_string = challenge + public_address + Web3.toHex(str.encode(str(nonce)))[2:]
		print ('string',_string)
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
	global miners_started
	print('starting masterMiner',miners_started + 1)
	while True:
		getAddress();
		challenge,difficulty = getVariables();
		print(challenge,difficulty);
		nonce = mine(challenge,public_keys[miners_started][2:],difficulty);
		print(nonce);
		miners_started += 1
		if(nonce > 0):
			print ("You guessed the hash");
			value = getAPIvalue();
			arg_string =""+ str(nonce) + " "+str(value)+" "+str(contract_address)+" "+str(public_keys[miners_started])+" "+str(private_keys[miners_started])
			run_js('submitter.js',arg_string);
			time.sleep(30)
		else:
			pass
	print('Miner Stopping')
	miners_started -= 1

def getVariables():
	print(contract_address)
	payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_call","params":[{"to":contract_address,"data":"0x94aef022"}, "latest"]}
	r = requests.post(node_url, data=json.dumps(payload));
	val = r.content
	d = jsonParser(r);
	print(d)
	val2 = val[100:]
	val2 = val2[:-3]
	_challenge = val[34:98].decode("utf-8")
	val3 = bytes.decode(val2)
	_difficulty = int(val3);
	return _challenge,_difficulty;

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
		payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_getTransactionByBlockNumberAndIndex","params":[hex(block),0]}
		r = requests.post(node_url, data=json.dumps(payload));
		d = jsonParser(r);
		tx = d['result']
		payload = {"jsonrpc":"2.0","id":net_id,"method":"eth_getTransactionReceipt","params":[tx['hash']]}
		r = requests.post(node_url, data=json.dumps(payload));
		d = jsonParser(r);
		tx = d['result']
		try:
			logs =tx['logs'][0]['data']
			if static_jazz1 and static_jazz2 in logs:
				contract_address = logs.replace(static_jazz1,'').replace(static_jazz2,'')
				last_block = block
				block = 0 ;
				print('New Contract Address',contract_address)
			else:
				block = block-1;
		except:
			block = block-1;

	return 

def bytes2int(str):
 return int(str.encode('hex'), 32)

def bytes_to_int(bytes):
    result = 0

    for b in bytes:
        result = result * 256 + int(b)

    return result



masterMiner();
#getAddress();

def runInParallel(*fns):
  proc = []


  for fn in fns:
  	if __name__ == '__main__':
  		freeze_support()
  		p = Process(target=fn)
  		p.start()
  		proc.append(p)
  for p in proc:
    p.join()

#runInParallel(masterMiner,masterMiner,masterMiner,masterMiner,masterMiner)



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