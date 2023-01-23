const { expect } = require('chai');
const { ethers, network, upgrades } = require('hardhat');
const { BigNumber, utils } = require('ethers');

const { time } = require("@nomicfoundation/hardhat-network-helpers");


function expandTo18Decimals(n) {
  return BigNumber.from(n).mul(BigNumber.from(10).pow(18))
}

async function getTimestamp() {
  var block = await ethers.provider.getBlock('latest')
  return new Date(block.timestamp * 1000)
}

const ROUTER = '0x7a250d5630b4cf539739df2c5dacb4c659f2488d'; // Uniswap V2 Router

const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'; // Wrapped Ether
const RPL  = '0xb4efd85c19999d84251304bda99e90b92300bd93'; // Rocket Pool 
const USDT = '0xdac17f958d2ee523a2206206994597c13d831ec7'; 
const MKR = '0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2'; // Maker DAO

const RPL_holder_address = '0xb4efd85c19999d84251304bda99e90b92300bd93';
const USDT_holder_address = '0x82e1d4ddd636857ebcf6a0e74b9b0929c158d7fb';
const MKR_holder_address = '0xa9dda2045d140eb7ccd30c4ef6b9901ccb279793';

const vitalik_eth = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';

let RPL_holder, USDT_holder, MKR_holder;

let adapter, maker, rocketPoolToken, usdt;


describe('UniswapV2Adapter', function () {
  beforeEach(async function () {
    [deployer,
      user1,
      user2,
      user3
    ] = await ethers.getSigners()

    const Adapter = await ethers.getContractFactory("UniswapV2Adapter")

    adapter = await Adapter.deploy(ROUTER, WETH);

    maker = await ethers.getContractAt('DSToken', MKR);
    rocketPoolToken = await ethers.getContractAt('RocketPoolToken', RPL)
    usdt = await ethers.getContractAt('TetherToken', USDT)

    
  })


  describe('Test methods', async function () {
    const amountToSwap = utils.parseEther("1.0")

    it('# setRoute', async function () {
        const routeToSet = [RPL, MKR, USDT]
        await adapter.connect(deployer).setRoute(RPL, MKR, routeToSet);

        const initialRoute = await adapter.routes(RPL, MKR, [0]);
      //  const reverseRoute = await adapter.routes(MAKER, RPL);


     //   let reverseCounter = routeToSet.length;

        for (let i = 0; i < routeToSet.length; ++i) {
            expect(initialRoute[i]).to.equal(routeToSet[i])
            //expect(reverseRoute[i]).to.equal(routeToSet[--reverseCounter])
        }  
    })

    it('# swap (without path)', async function () {  
        await hre.network.provider.request({
          method: 'hardhat_impersonateAccount',
          params: [USDT_holder_address],
        })
  
        USDT_holder = await ethers.getSigner(USDT_holder_address)
  
        await usdt
          .connect(USDT_holder)
          .approve(adapter.address, ethers.constants.MaxUint256)
  
        await adapter
          .connect(USDT_holder)
          .swap(USDT, amountToSwap, MKR, 5)
  
  
        await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [USDT_holder_address],
        })
      })
  })
})