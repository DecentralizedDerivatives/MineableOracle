import React, { Component } from 'react'
import OracleTokenContract from '../build/contracts/OracleToken.json';
import getWeb3 from './utils/getWeb3'
import update from 'immutability-helper';
import Chart from 'chart.js';
import moment from 'moment';
var LineChart = require('react-chartjs').Line;

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

import {Button,Grid,Row,Col} from 'react-bootstrap'

class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      storageValue: 0,
      web3: null,
      chart:null
    }
  }

  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
    .then(results => {
      this.setState({
        web3: results.web3,
        etherValue: null,
        challengeValue: null,
        lastTenTimeStamps: [1,2,3,4,5,6,7,8,9,10],
        readableTimeStamps: [1,2,3,4,5,6,7,8,9,10],
        difficultyValue: null,
        etherValues: [0,0,0,0,0,0,0,0,0,0],
        currentValue: 0,
        accountNum: null
      })

      // Instantiate contract once web3 provided.
      this.instantiateContract()
    })
    .catch(() => {
      console.log('Error finding web3.')
    })
    
  }

  instantiateContract() {
    /*
     * SMART CONTRACT EXAMPLE
     *
     * Normally these functions would be called in the context of a
     * state management library, but for convenience I've placed them here.
     */

    const contract = require('truffle-contract')
    const oracleToken = contract(OracleTokenContract)
    oracleToken.setProvider(this.state.web3.currentProvider)

    //use this to get current epoch
    var ts = Math.round((new Date()).getTime() / (1000));
    var timestamp = ts - (ts % 60);

    console.log(moment.unix(timestamp).format('dddd, MMMM Do, YYYY h:mm:ss A'));

    var tempTimeStamps = [];
    var tempReadableTimeStamps = [];
    
    for (var i=600; i>0; i-=60){
      tempTimeStamps.push(timestamp - i)
      tempReadableTimeStamps.push(moment.unix(timestamp - i).format('dddd, MMMM Do, YYYY h:mm:ss A'));
    }

    this.setState({lastTenTimeStamps: tempTimeStamps})
    this.setState({readableTimeStamps: tempReadableTimeStamps})
    var oracleTokenInstance
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060200, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {0: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060260, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {1: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060320, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {2: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060380, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {3: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060440, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {4: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060500, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {5: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060560, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {6: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060620, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {7: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060680, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({etherValues: update(this.state.etherValues, {8: {$set: tempNum2}}) })
      })
    })
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060740, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({
          etherValues: update(this.state.etherValues, {9: {$set: tempNum2}}),
          currentValue: tempNum2
        })
      })
    })

    // Get accounts.
    this.state.web3.eth.getAccounts(async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).getVariables({from: accounts[0]})
      .then((result) => {
        let challenge = result[0] - 0
        let difficulty = result[1] - 0
        
          return this.setState({challengeValue: challenge, difficultyValue: difficulty})
      });
    })
  }
  componentDidMount () {
    let chartCanvas = this.refs.chart;
  
    let myChart = new Chart(chartCanvas, {
      type: 'line',
      data: {
        labels: this.state.readableTimeStamps,
        datasets: [
          {
            label: "Bitcoin > USD",
            fillColor: "rgba(5,113,259,0.2)",
            strokeColor: "rgba(5,113,259,1)",
            pointColor: "rgba(5,113,259,1)",
            pointStrokeColor: "#fff",
            pointHighlightFill: "#fff",
            pointHighlightStroke: "rgba(5,113,259,1)",
            data: this.state.etherValues
          }
        ]
      },
      options: {
        ///Boolean - Whether grid lines are sho across the chart
        scaleShowGridLines : true,
        //String - Colour of the grid lines
        scaleGridLineColor : "rgba(0,0,0,.05)",
        //Number - Width of the grid lines
        scaleGridLineWidth : 1,
        //Boolean - Whether to show horizontal lines (except X axis)
        scaleShowHorizontalLines: true,
        //Boolean - Whether to show vertical lines (except Y axis)
        scaleShowVerticalLines: true,
        //Boolean - Whether the line is curved between points
        bezierCurve : true,
        //Number - Tension of the bezier curve between points
        bezierCurveTension : 0.4,
        //Boolean - Whether to show a dot for each point
        pointDot : true,
        //Number - Radius of each point dot in pixels
        pointDotRadius : 4,
        //Number - Pixel width of point dot stroke
        pointDotStrokeWidth : 1,
        //Number - amount extra to add to the radius to cater for hit detection outside the drawn point
        pointHitDetectionRadius : 20,
        //Boolean - Whether to show a stroke for datasets
        datasetStroke : true,
        //Number - Pixel width of dataset stroke
        datasetStrokeWidth : 2,
        //Boolean - Whether to fill the dataset with a colour
        datasetFill : true,
        //String - A legend template
        legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<datasets.length; i++){%><li><span style=\"background-color:<%=datasets[i].strokeColor%>\"><%if(datasets[i].label){%><%=datasets[i].label%><%}%></span></li><%}%></ul>",
        //Boolean - Whether to horizontally center the label and point dot inside the grid
        offsetGridLines : false
      }
    });
  
    this.setState({chart: myChart});
  }
  componentDidUpdate () {
      let chart = this.state.chart;
      let data = {
        labels: this.state.readableTimeStamps,
        datasets: [
          {
            label: "Bitcoin > USD",
            fillColor: "rgba(5,113,259,0.2)",
            strokeColor: "rgba(5,113,259,1)",
            pointColor: "rgba(5,113,259,1)",
            pointStrokeColor: "#fff",
            pointHighlightFill: "#fff",
            pointHighlightStroke: "rgba(5,113,259,1)",
            data: this.state.etherValues
          }
        ]
      }
  
      data.datasets.forEach((dataset, i) => chart.data.datasets[i].data = dataset.data);
  
      chart.data.labels = data.labels;
      chart.update();
  }
  getNewValue(){
    const contract = require('truffle-contract')
    const oracleToken = contract(OracleTokenContract)
    oracleToken.setProvider(this.state.web3.currentProvider)
    var ts = Math.round((new Date()).getTime() / 1000);
    this.state.web3.eth.getAccounts( async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).retrieveData(1531060560, {from: accounts[0]})
      .then((result) => {
        let tempNum2 = result - 0;
        return this.setState({currentValue: tempNum2})
      })
    })

    // Get accounts.
    this.state.web3.eth.getAccounts(async(error, accounts) => {
      const instance = await oracleToken.at(
        '0x3ce33bc3ebe0358eeb8e4a9f0ebcd7df4fea6bfc'
      ).getVariables({from: accounts[0]})
      .then((result) => {
        let challenge = result[0] - 0
        let difficulty = result[1] - 0
        
          return this.setState({challengeValue: challenge, difficultyValue: difficulty})
      });
    })
  }
  render() {
    let imgUrl = 'https://new.consensys.net/wp-content/themes/consensys/client/images/masthead-organic-poster.jpg';
    let minerImageUrl = 'https://media.istockphoto.com/vectors/cartoon-dwarf-miner-vector-id839970312';
    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
            <a href="#" className="pure-menu-heading pure-menu-link">MOC Token</a>
        </nav>
        <div className="container-fluid" style={{backgroundColor:'rgb(250, 250, 250)'}}>
          <div style={{backgroundImage: 'url(' + imgUrl + ')',
                height:400,
                width:'100%',
                display:'flex',
                justifyContent:'center'}}>
            <h1 style={{
              color:'white',
              alignSelf:'center'
              }}>Minable Oracle Contract</h1>
          </div>
          <Grid fluid={true} style={{margin:50,padding:50}}>
            <Row>
              <Col md={8}>
                <h3 style={{alignSelf: 'center'}}>Description</h3>
                <p>
      "Minable Oracle Contract (MOC) is an oracle schema that implements a mineable proof of work (POW) competiton. Once aggregated, validated, and processed into a consumable output, these oracle data entries will be internally referred to as 'truthpoints'.
                </p>
                <p>MOC leverages a novel game-theoretical competition in an attempt to disintermediate and decentralize the existing 3rd party trust layer associated with centralized oracle services like Oraclize, whcih use basic API getters to provide smart-contracts with off-chain data. This reduces the implicit cost of risk associated with third parties.
                </p>
              </Col>
              <Col md={4}>
                <img src={minerImageUrl} style={{width: 300,height:300,borderRadius:25}} />
              </Col>
            </Row>
          </Grid>
          <Grid style={{backgroundColor:'rgb(0, 3, 102)',borderRadius:25}} fluid={true}>
            <Row style={{padding:10}}>
              <Col md={4} lg={4} style={{color:'white'}}>
              <img src={'http://www.clker.com/cliparts/r/S/B/V/g/h/1-extreme-risk.svg'} style={{width:200,height:200,borderRadius:50}} />
                <h4><strong>Reduce the risks</strong></h4>
                <hr style={{borderColor: 'white'}}/>
                <p>associated with single-party oracle providers, who can cut access to API data, forge message data, etc</p>
              </Col>
              <Col md={4} lg={4} style={{color:'white'}}>
                <img src={'https://image.flaticon.com/icons/svg/203/203878.svg'} style={{width:200,height:200,borderRadius:50}} />
                <h4><strong>Lay the foundation</strong></h4>
                <hr style={{borderColor: 'white'}}/>
                <p>for a superior oracle system where truth data is derived from a distributed set of participants which have both economic interest and 'stake' in the validity and success of the oracle data</p>
              </Col>
              <Col md={4} lg={4} style={{color:'white'}}>
                <img src={'https://upload.wikimedia.org/wikipedia/commons/7/72/Ego_network.png'} style={{width:200,height:200,borderRadius:50}} />
                <h4><strong>Create</strong></h4>
                <hr style={{borderColor: 'white'}}/>
                <p >an effective, secure, and decentralized oracle system which inputs data from multiple parties and disincentives incorrect submissions</p>
              </Col>
            </Row>
          </Grid>
          <Grid fluid={true} style={{marginTop:50}}>
            <Row style={{marginLeft:50}}>
              <h3>Most recent transaction data</h3>
            </Row>
            <Row style={{marginLeft:50,marginTop:50}}>
              <Col md={3} style={{borderStyle:'solid',borderWidth:2,borderRadius:10,marginRight:10}}>
                <h3>Bitcoin/USD exchange rate: {this.state.currentValue}</h3>
              </Col>
              <Col md={4} style={{borderStyle:'solid',borderWidth:2,borderRadius:10,marginRight:10}}>
                <h3>Challenge Level: {this.state.challengeValue}</h3>
              </Col>
              <Col md={3} style={{borderStyle:'solid',borderWidth:2,borderRadius:10}}>
                <h3>Difficulty: {this.state.difficultyValue}</h3>
              </Col>
            </Row>
            <Row style={{justifyContent:'center',marginTop:50}}>
              <Button bsStyle="primary" bsSize="large" onClick={this.getNewValue.bind(this)}>Get current value</Button>
            </Row>
          </Grid>
          <Grid fluid={true}>
          <Row style={{justifyContent:'center'}}>
            <Col md={8}>
          <h3 style={{marginTop:50}}>Price over the last 20 minutes</h3>
          </Col>
          </Row>
          <Row>
          <canvas ref={'chart'} height={'300'} width={'600'} style={{paddingRight:200,paddingLeft:200,paddingBottom:100}}></canvas>
          </Row>
          </Grid>
          <Grid style={{backgroundColor:'rgb(0, 3, 102)',borderRadius:25,paddingBottom:20}} fluid={true}>
            <Row style={{paddingTop:20,paddingLeft:20}}>
              <Col style={{color:'white'}}>
                <h3>Links</h3>
              </Col>
            </Row>
            <Row style={{padding:10,display:'flex',justifyContent:'space-around'}}>
              <Col md={4} lg={4} style={{color:'white',marginTop:20}}>
                  <a style={{color:'white'}}href={'https://github.com/SamuelLJackson/AngelHackTeam'}>
              <img src={'https://assets-cdn.github.com/images/modules/logos_page/GitHub-Mark.png'} style={{width:100,height:100,borderRadius:50}} />
                <h4>
                    <strong>Github Repo</strong>
                </h4>
                  </a>
              </Col>
              <Col md={4} lg={4} style={{color:'white',marginTop:20}}>
                <a href={'https://rinkeby.etherscan.io/address/0x34f65d2d9da5022592ba7e921783b9f5b1697333'} style={{color:'white'}}>
                  <img src={'https://cdn.worldvectorlogo.com/logos/metamask.svg'} style={{width:100,height:100}} />
                  <h4>
                    <strong>Contract Address</strong>
                  </h4>
                </a>
              </Col>
              <Col md={4} lg={4} style={{color:'white',marginTop:20}}>
              <a href={'mailto:nfett@decentralizedderivatives.org'} style={{color: 'white'}}>
                <img src={'https://www.freeiconspng.com/uploads/white-envelope-icon-png-15.jpg'} style={{height:100,borderRadius:20}} />
                <h4><strong>Contact</strong></h4>
              </a>
              </Col>
            </Row>
          </Grid>
        </div>
      </div>

    );
  }
}

export default App
