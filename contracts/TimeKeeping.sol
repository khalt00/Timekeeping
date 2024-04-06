// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AttendanceContract {
    enum Type {
        CheckIn, //0
        CheckOut //1
    }

    struct Attendance {
        uint256 id;
        address employeeID;
        uint256 date;
        string details;
        Type attendanceType;
    }

    event AttendanceEvent(
        address employeeID,
        uint256 date,
        string details,
        Type attendanceType
    );

    event UpdateAttendanceEvent(uint256 id, string details);

    uint256 private _id;
    mapping(address => address) private employeeAddress; //for fast search

    mapping(address => Attendance[]) private employeeAttendances; //userAddress => user Attendance[]
    Attendance[] private employeeRecords; //attendance list

    address[] private employees;

    address private owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function"
        );
        _;
    }

    modifier onlyEmployee() {
        require(
            _isUser() || msg.sender == owner,
            "Only employee can call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function _isUser() internal view returns (bool) {
        for (uint i = 0; i < employees.length; i++) {
            if (employees[i] == msg.sender) return true;
        }
        return false;
    }

    function addUser(address _user) public onlyOwner {
        require(employeeAddress[_user] != _user, "User already exists");
        employees.push(_user);
        employeeAddress[_user] = _user;
    }

    function removeUser(address _user) public onlyOwner {
        require(employeeAddress[_user] == _user, "User is not exists");

        for (uint256 i = 0; i < employees.length; i++) {
            if (employees[i] == _user) {
                employees[i] = employees[employees.length - 1];
                employees.pop();
                delete employeeAddress[_user];
                break;
            }
        }
    }

    function getUsers() public view onlyOwner returns (address[] memory) {
        return employees;
    }

    function isEmployeeCheckedInOrCheckedOut(
        address employeeID,
        uint256 _day,
        uint256 _month,
        uint256 _year,
        Type _type
    ) private view returns (bool) {
        for (uint256 i = 0; i < employeeRecords.length; i++) {
            Attendance memory record = employeeRecords[i];
            if (
                record.employeeID == employeeID &&
                record.attendanceType == _type &&
                isSameDate(record.date, _day, _month, _year)
            ) {
                return true;
            }
        }
        return false;
    }

    function isSameDate(
        uint256 _timestamp,
        uint256 _day,
        uint256 _month,
        uint256 _year
    ) internal pure returns (bool) {
        (uint256 day, uint256 month, uint256 year) = timestampToDate(
            _timestamp
        );
        return (day == _day && month == _month && year == _year);
    }

    function timestampToDate(
        uint256 timestamp
    ) internal pure returns (uint256 day, uint256 month, uint256 year) {
        uint256 secondsInDay = 86400; // 60 seconds * 60 minutes * 24 hours
        uint256 secondsInYear = 31536000; // 60 seconds * 60 minutes * 24 hours * 365 days

        year = timestamp / secondsInYear;
        uint256 remainder = timestamp % secondsInYear;

        bool isLeapYear = (year % 4 == 0 &&
            (year % 100 != 0 || year % 400 == 0));

        uint8[12] memory daysInMonth = isLeapYear
            ? [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
            : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

        for (uint256 i = 0; i < 12; i++) {
            uint256 monthDays = daysInMonth[i] * secondsInDay;
            if (remainder < monthDays) {
                month = i + 1;
                day = remainder / secondsInDay + 1;
                break;
            }
            remainder -= monthDays;
        }
    }

    function recordAttendance(
        Type _attendanceType,
        string memory _details
    ) public onlyEmployee {
        // Ensure employeeID is valid (implementation for validation logic here)
        uint256 _date = block.timestamp; // Use block timestamp for date
        (uint256 day, uint256 month, uint256 year) = timestampToDate(_date);
        address _employeeID = msg.sender;

        if (_attendanceType == Type.CheckOut) {
            if (
                isEmployeeCheckedInOrCheckedOut(
                    _employeeID,
                    day,
                    month,
                    year,
                    Type.CheckIn
                )
            ) {
                require(
                    !isEmployeeCheckedInOrCheckedOut(
                        _employeeID,
                        day,
                        month,
                        year,
                        Type.CheckOut
                    ),
                    "Employee is already checkedout"
                );
            } else {
                revert("Employee is not checkedin");
            }
        } else {
            require(
                !isEmployeeCheckedInOrCheckedOut(
                    _employeeID,
                    day,
                    month,
                    year,
                    Type.CheckIn
                ),
                "Employee is already checkedin"
            );
        }

        employeeRecords.push(
            Attendance(++_id, _employeeID, _date, _details, _attendanceType)
        );

        employeeAttendances[_employeeID] = employeeRecords;

        emit AttendanceEvent(_employeeID, _date, _details, _attendanceType);
    }

    function updateAttendance(
        uint256 _attendanceID,
        string memory _details
    ) public onlyOwner {
        for (uint256 i = 0; i < employeeRecords.length; i++) {
            if (employeeRecords[i].id == _attendanceID) {
                employeeRecords[i].details = _details;

                Attendance[] memory currentAttendances = employeeAttendances[
                    employeeRecords[i].employeeID
                ];
                for (uint256 j = 0; j < currentAttendances.length; j++) {
                    if (currentAttendances[j].id == _attendanceID) {
                        currentAttendances[j].details = _details;
                    }
                }
                emit UpdateAttendanceEvent(_attendanceID, _details);
                return;
            }
        }

        revert("_attendanceID not found");
    }

    function getAttendanceByDateRange(
        uint256 _startDate,
        uint256 _endDate
    ) public view returns (Attendance[] memory) {
        require(_startDate <= _endDate, "Invalid date range");
        // Determine the number of attendance records within the date range
        uint256 count = 0;
        for (uint256 i = 0; i < employeeRecords.length; i++) {
            if (
                employeeRecords[i].date >= _startDate &&
                employeeRecords[i].date <= _endDate
            ) {
                count++;
            }
        }

        Attendance[] memory result = new Attendance[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < employeeRecords.length; i++) {
            if (
                employeeRecords[i].date >= _startDate &&
                employeeRecords[i].date <= _endDate
            ) {
                result[index] = employeeRecords[i];
                index++;
            }
        }
        return result;
    }

    function getAttendanceByEmployeeID(
        address _employeeID
    ) public view onlyOwner returns (Attendance[] memory) {
        return employeeAttendances[_employeeID];
    }

    function getAttendances()
        public
        view
        onlyOwner
        returns (Attendance[] memory)
    {
        return employeeRecords;
    }
}
