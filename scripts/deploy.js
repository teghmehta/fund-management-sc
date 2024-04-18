require('dotenv').config();
const { METAMASK_ADDRESS } = process.env;

async function main() {
    const FundManagement = await ethers.getContractFactory("FundManagement");
    const fundMan = await FundManagement.deploy(METAMASK_ADDRESS);
    console.log("Contract deployed to address:", fundMan.address);
 }

 main()
   .then(() => process.exit(0))
   .catch(error => {
     console.error(error);
     process.exit(1);
   });

// run the command: npx hardhat run scripts/deploy.js --network goerli