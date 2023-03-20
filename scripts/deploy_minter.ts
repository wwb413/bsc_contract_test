// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
//import { ethers } from "hardhat";

import {ethers} from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const LpMinter = await ethers.getContractFactory("LpMinter");
  //const starGirl = await StarGirl.deploy("0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1");
  const lpMinter = await LpMinter.deploy("0x0f98BB4Bdb64f61E0F797200e0e4b4d1A6928323","0xdC34eD2A70Ed825Fddd32B91215D453E0997c3f5","0xdC34eD2A70Ed825Fddd32B91215D453E0997c3f5",1000,28215000);
  //const starGirl = await StarGirl.deploy("0xf69186dfBa60DdB133E91E9A4B5673624293d8F8");
  //await swapLimit.deployed();

  console.log("ape deployed to:", lpMinter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
