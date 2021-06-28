pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract Registration{
    address public admin;
    mapping(address => bool) public manufacturer;
    mapping(address => bool) public distributor;
    mapping(address => bool) public center;
    mapping(address => bool) public doctor;
    mapping(address => bool) public nurse;
    
    // events
    event RegistrationInitiated(address indexed admin);
    
    // modifiers
    modifier onlyAdmin(){
        require(msg.sender == admin, "Only the admin is able to run this function.");
        _;
    }
    
    modifier onlyCenter(){
        require(center [msg.sender], "Only registered centers are able to run this function.");
        _;
    }
    
    // constructor
    constructor() public{
        admin = msg.sender;
        emit RegistrationInitiated(admin);
    }
    
    // functions
    function manufacturerRegistration(address user) public onlyAdmin{
        require(manufacturer[user] == false, "This manufacturer is already registered.");
        manufacturer[user] = true;
    }
    
    function distributorRegistration(address user) public onlyAdmin{
        require(distributor[user] == false, "This distributor is already registered.");
        distributor[user] = true;
    }
    
    function centerRegistration(address user) public onlyAdmin{
        require(center[user] == false, "This center is already registered.");
        center[user] = true;
    }
    
    function doctorRegistration(address user) public onlyCenter{
        require(doctor[user] == false, "This doctor is already registered.");
        doctor[user] = true;
    }
    
    function nurseRegistration(address user) public onlyCenter{
        require(nurse[user] == false, "This nurse is already registered.");
        nurse[user] = true;
    }
}

contract Lot{
    Registration public registrationcontract1;
    address payable internal ownerID;
    
    mapping(address => uint) public boxesPatient; 
    
    struct lotdata{
        string lotName;
        uint numBoxes;
        uint lotPrice; 
        uint boxPrice; 
    }
    
    lotdata internal lot;
    
    // events
    event newOwner(address oldownerID,address newownerID);
    event lotManufactured(address manufacturer);
    event lotSale(string _lotName,uint _numBoxes, uint _lotPrice, uint _boxPrice);
    event lotSold(address newownerID);
    event boxesSold(uint _soldBoxes, address newownerID);
    
    constructor(address registrationaddress) public {
        
        registrationcontract1 = Registration(registrationaddress);
        ownerID = msg.sender;
        emit newOwner(address(0), ownerID);

    }
    
    function currentOwner() external view returns (address _currentOwner){
        return ownerID;
    }
    
    // modifiers
    modifier onlyManufacurer() {
        require(registrationcontract1.manufacturer(msg.sender));
        _;
    }
    
        modifier onlyDistributor() {
        require(registrationcontract1.distributor(msg.sender));
        _;
    }
    
        modifier onlyCenter() {
        require(registrationcontract1.center(msg.sender));
        _;
    }
    
    function lotDetails(string calldata _lotName, uint _lotPrice,uint _numBoxes, uint _boxPrice) external onlyManufacurer() {
        
        lot.lotName = _lotName;
        lot.lotPrice = _lotPrice;
        lot.numBoxes = _numBoxes;
        lot.boxPrice = _boxPrice;
        
        //ownerID = msg.sender;
        
        emit lotManufactured(msg.sender);
    }
    
    function grantSale() external onlyManufacurer() onlyDistributor(){
        
        emit lotSale(lot.lotName,lot.numBoxes,lot.lotPrice,lot.boxPrice);
    
    } 
    
    function buyLot () external onlyDistributor() onlyCenter() payable {
        address payable buyer = msg.sender;
        address payable seller = ownerID;
        require(buyer != seller, "The lot is already owned by the function caller");
        require(msg.value == lot.lotPrice, "insufficient payment"); 

        seller.transfer(lot.lotPrice); 
        ownerID = buyer; 
        
        emit lotSold(ownerID); 

    
        
    }
    
    function buyBox (uint numboxes2buy) external payable {
        address payable buyer = msg.sender;
        address payable seller = ownerID; 
        require(numboxes2buy <= lot.numBoxes, "The specified amount exceeds the limit");
        require(msg.value == lot.boxPrice*numboxes2buy, "incorrect payment");
 
        seller.transfer(lot.boxPrice*numboxes2buy); 
        lot.numBoxes -= numboxes2buy;
        boxesPatient[buyer] = numboxes2buy;
        
        emit boxesSold(numboxes2buy, ownerID);  
        
    }
    
    function viewLot () external view returns(lotdata memory) {
        
        return(lot);
        
    }
    
    function viewBox (address _account) external view returns(uint _boxesPatient){
        return(boxesPatient[_account]);
    }
}

contract SmartContainer{
    Registration public registrationcontract2;
    Lot public lotcontract;
    address public container;
    address public manufacturer;
    address vaccination_center;
    string container_content; 
    enum containerStatus {NotReady, ReadyforDelivery, StartDelivery, onTrack, EndDelivery, ContainerReceived, Violated}
    containerStatus public state;
    uint startTime;
    enum violationType { None, Temp, Open, Light, Route}
    violationType public violation;
    int temperature;
    int open;
    int track;
    int light;
    
    // events
    event ContainerOwnership (address previousowner, address newowner); 
    event ContainerReadyForDelivery (address manufacturer); 
    event DeliveryStart (address distributor); 
    event DeliveryEnd(address distributor); 
    event ContainerReception(address vaccination_center); 
    
    // violations
    event TemperatureViolation( int v); 
    event ContainerOpening( int v);
    event OffTrack( int v);
    event LightExposure ( int v);
    event ErrorNoValidViolation();
    
    // modifiers
    modifier onlyManufacturer(){
        require(registrationcontract2.manufacturer(msg.sender), "Only authorised manufacturers can run this function.");
        _;
    }
    
    modifier onlyDistributor(){
        require(registrationcontract2.distributor(msg.sender), "Only authorised distributors can run this function.");
        _;
    }
    
    modifier onlyCenter(){
        require(registrationcontract2.center(msg.sender), "Only authorised centers can run this function.");
        _;
    }
    
    modifier onlyContainer(){
        require(container == msg.sender, "The sender is not eligible to run this function.");
        _;
    }
    
    // constructor
    constructor(address lotaddress, address regaddress) public payable{
        lotcontract = Lot(lotaddress);
        registrationcontract2 = Registration(regaddress);
        manufacturer = msg.sender;
        startTime = block.timestamp;
        container = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        vaccination_center = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        container_content = "This container contains X amount of Vaccine doses.";
        state = containerStatus.NotReady;//NotReady
        emit ContainerOwnership(address(0), manufacturer);
    }
    
    // tracking
    function CreateContainer() public onlyManufacturer{
        require(state == containerStatus.NotReady, "The smart container has already been created");
        state = containerStatus.ReadyforDelivery;
        emit ContainerReadyForDelivery(msg.sender);
    }
    
    function StartDelivery() public onlyDistributor{
        require(state == containerStatus.ReadyforDelivery, "Can't start delivery before creating the container");
        state = containerStatus.onTrack;
        emit DeliveryStart(msg.sender);
    }
    
    function EndDelivery() public onlyDistributor{
        require(state == containerStatus.onTrack, "Can't end delivery before announcing the start of it");
        state = containerStatus.EndDelivery;
        emit DeliveryEnd(msg.sender);
        
    }
    
    function ReceiveContainer() public onlyCenter{
        require(state == containerStatus.EndDelivery, "Can't receive the container before announcing the end of the");
        state = containerStatus.ContainerReceived;
        emit ContainerReception(msg.sender);
    }
    
    // violations
    function violationOccurrence(violationType v, int value) public onlyContainer{
        require(state == containerStatus.onTrack, "The container is not being delivered");
        
        state = containerStatus.Violated;
        if(v == violationType.Temp){
             
            emit TemperatureViolation( value);
        }
        else if (v == violationType.Open){
            //either 1 or 0
            emit ContainerOpening ( value);
        }
        else if (v == violationType.Route){
           
            emit OffTrack(  value);
        }
        else if (v == violationType.Light){
           
            emit LightExposure( value);
        }
        else
            emit ErrorNoValidViolation();
    }
}

contract Consumption{
    
    //Declaring variables
    
    Registration registrationcontract3; 
    //Production schain;
    
    bytes32 public patientID;
    bytes32 public patientName;
    bytes32 public endorsements;
    bytes32 public prescriptionIPFShash;
    bytes32 public nurseName;
    bytes32 public sheetIPFShash; 
    bytes32 public disposalsheetIPFShash;
    uint public patientAge;
    uint public prescriptionDate;
    uint public administrationDate;
    uint public availableAmount; 
    uint public dispensedAmount;
    uint public disposedAmount;
    uint public disposalDate;
    
    
    enum Drugstate {NotReady, ReadyForDispensing, Prescribed, Administered, Disposed}
    Drugstate public drugstate; //refers to the state of the controlled drug after unboxing
        
    //Events  
    
    event ConsumptionSCDeployer(address indexed _address); 
    event DrugReady(address indexed _hospital, uint _amount);
    event DrugPrescribed (address indexed prescriber, bytes32 patientID, bytes32 patientName, uint patientAge, bytes32 endorsements, bytes32 prescriptionIPFShash);
    event DrugAdministered(address indexed _nurse, bytes32 nurseName, uint administrationDate, uint dispensedAmount, bytes32 sheetIPFShash);
    event DrugDisposed(address indexed nurse, bytes32 nurseName, uint disposalDate, uint disposedAmount, bytes32 disposalsheetIPFShash);
    
    //Modifiers
    
    modifier onlyHospital(){
    
        require(registrationcontract3.center(msg.sender), "Only the hospital is allowed to execute this function");
        _;
    }
    
    modifier onlyPrescriber(){
    
        require(registrationcontract3.doctor(msg.sender), "Only the prescriber is allowed to execute this function");
        _;
    }
 
     modifier onlyNurse(){
    
        require(registrationcontract3.nurse(msg.sender), "Only the nurse is allowed to execute this function");
        _;
    }
       
    
    //Constructor 
    
    constructor(address registrationaddress) public {
        
        registrationcontract3 = Registration(registrationaddress);
        //schain = Production(supplyaddress);
        emit ConsumptionSCDeployer(msg.sender); //Should be changed to msg.sender if someone else will deploy the SC other than the CDR
        
    }
    
    

    //Consumption contract Functions
    
    
    function DrugReadyForDispensing(uint amount) public onlyHospital{
        require(drugstate == Drugstate.NotReady, "Other entities have already been made aware of this state of the drug");
        drugstate = Drugstate.ReadyForDispensing;
        availableAmount = amount;
        emit DrugReady(msg.sender, availableAmount);
        
    }
    
    function DrugPrescription(bytes32 _patientID, bytes32 _patientName, uint _patientAge, bytes32 _endorsements, bytes32 _prescriptionIPFShash) public onlyPrescriber{
        
        require(drugstate == Drugstate.ReadyForDispensing , "Can't prescribe controlled drug before it's ready");
        patientID = _patientID;
        patientName = _patientName;
        patientAge = _patientAge;
        endorsements = _endorsements;
        prescriptionIPFShash = _prescriptionIPFShash;
        drugstate = Drugstate.Prescribed; 
        emit DrugPrescribed(msg.sender, patientID, patientName, patientAge, endorsements, prescriptionIPFShash);
    }
    
    function DrugAdministration(bytes32 _nurseName, uint _administrationDate, uint _dispensedAmount, bytes32 _sheetIPFShash) public onlyNurse{
        require(drugstate == Drugstate.Prescribed, "Controlled drugs must be prescribed first before administration");
        require(_dispensedAmount <= availableAmount , "The dispensed amount must be less than or equal to the available amount");
        nurseName = _nurseName;
        administrationDate = _administrationDate;
        dispensedAmount = _dispensedAmount;
        sheetIPFShash = _sheetIPFShash;
        availableAmount -= dispensedAmount; 
        drugstate = Drugstate.Administered;
        emit DrugAdministered(msg.sender, nurseName, administrationDate, dispensedAmount, sheetIPFShash);
    }
    
    function DrugDisposal(bytes32 _nurseName, uint _disposalDate, uint _disposedAmount, bytes32 _disposalsheetIPFShash) public onlyNurse{
        require(drugstate == Drugstate.Administered, "Can't dispose drugs before they have been administired");
        require(_disposedAmount <= availableAmount , "The dispensed amount must be less than or equal to the available amount");
        availableAmount -= _disposedAmount;
        nurseName = _nurseName;
        disposalDate = _disposalDate;
        disposalsheetIPFShash = _disposalsheetIPFShash;
        drugstate = Drugstate.Disposed;
        emit DrugDisposed(msg.sender, nurseName, disposalDate, disposedAmount, disposalsheetIPFShash);

    }
    


        
}