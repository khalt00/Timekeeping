import { ethers } from "hardhat";
const { expect } = require("chai");

describe("AttendanceContract", function () {
  let AttendanceContract;
  let attendanceContract: any;
  let owner: any;
  let addr1: any; // Another address for testing purposes

  beforeEach(async function () {
    AttendanceContract = await ethers.getContractFactory("AttendanceContract");
    attendanceContract = await AttendanceContract.deploy();

  });

});