import { ethers } from "hardhat";

async function main() {
    const TimeKeeping = await ethers.getContractFactory('AttendanceContract');
    const timeKeeping = await TimeKeeping.deploy();

    console.log('Timekeeping deploy to mumbai with address:', timeKeeping.target);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });