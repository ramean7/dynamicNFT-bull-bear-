// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";


contract DynamicNFT2 is ERC721, ERC721Enumerable, ERC721URIStorage, VRFConsumerBaseV2Plus,AutomationCompatibleInterface,ReentrancyGuard{
    using Counters for Counters.Counter;

    error notEnoughMoney();
    error PriceFeedDdosed();  
    error InvalidRoundId();  
    error StalePriceFeed();
    error notEnugh();
    
    enum Trend { Bull, Bear }

    event NFTMinted(address to, uint256 tokenId);
    event NFTMinted1(address to, uint256 tokenId);

    mapping(uint256 => Trend) public trendMap;

    Counters.Counter public tokenIdCounter;        

    uint256 public interval;
    uint256 public lastTimeStamp;
    uint256 counter;        
    Trend public currentTrend = Trend.Bull;

    AggregatorV3Interface public priceFeed;
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    uint256 lastPrice;
    uint32 internal HEARTBEAT;
    uint256 public mintPriceWei = 10 * 10**18;

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    
    uint256 public s_subscriptionId;

   
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 public keyHash =
        0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887;
    
    uint32 public callbackGasLimit = 500000;
   
    uint16 public requestConfirmations = 3;
    
    uint32 public numWords = 1;    

    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];    

    constructor(address vrf,address feed,uint256 updateInterval,uint256 subscriptionId,uint32 heart)
        ERC721("dynamicNFT2", "mandal2")        
        VRFConsumerBaseV2Plus(vrf)             
        
    {
        priceFeed = AggregatorV3Interface(feed);
        lastPrice = 0;      
        interval = updateInterval;
        lastTimeStamp = block.timestamp;    
        s_subscriptionId = subscriptionId; 

        counter = 0;
        HEARTBEAT = heart;
    }

    function ownerMint(address to) external onlyOwner returns (uint256) {
    uint256 tokenId = tokenIdCounter.current();
    tokenIdCounter.increment();

    string memory uri = bullUrisIpfs[0];
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);

    emit NFTMinted1(msg.sender, tokenId);
    return tokenId;
}


    function safeMint()
        public    
        payable    
        nonReentrant          
        returns (uint256)
    {
        if(getUsdFromEth(msg.value) < mintPriceWei){
            revert notEnoughMoney();
        }
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        string memory uri = bullUrisIpfs[0];
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit NFTMinted(msg.sender, tokenId);
        return tokenId;
    }

    function getUsdFromEth(uint256 amount) public view returns (uint256) {
        uint256 price =  getChainlinkDataFeedLatestAnswer() * (10 ** 10);
        uint256 usdWei = Math.mulDiv(amount , price , 10**18);
        return usdWei;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override nonReentrant{
         if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }        

        uint256 currrentPrice = getChainlinkDataFeedLatestAnswer(); 

        if(currrentPrice == lastPrice){
            return;
        }
        
        if(currrentPrice > lastPrice){            
            requestRandomWords(false,Trend.Bull);
        }
        
        if(currrentPrice < lastPrice){            
            requestRandomWords(false,Trend.Bear);
        }

        lastPrice = currrentPrice;        
    }

    function requestRandomWords(
        bool enableNativePayment,
        Trend trend 
    ) internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        
        requestIds.push(requestId);
        lastRequestId = requestId;
        trendMap[lastRequestId]=trend;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        Trend trend = trendMap[_requestId];

        if(currentTrend == trend){
            return;
        }

        if(trend == Trend.Bull){
            
            bull(_randomWords[0]);
            currentTrend = Trend.Bull;
        }
        if(trend == Trend.Bear){
            
            bear( _randomWords[0]);
            currentTrend = Trend.Bear;
        }

        emit RequestFulfilled(_requestId, _randomWords);
    }       

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    

    function bull(uint256 seed)internal{
        uint256 count = tokenIdCounter.current();
        for(uint i=0 ; i< count; i++){
            uint256 uniqueNFTIndex = (seed + i) % bullUrisIpfs.length; 
            _setTokenURI(i,bullUrisIpfs[uniqueNFTIndex]);
        }
    }

    function bear(uint256 seed)internal{
        uint256 count = tokenIdCounter.current();
        for(uint i = 0; i < count; i++){
            uint256 uniqueNFTIndex = (seed + i) % bearUrisIpfs.length; 
            _setTokenURI(i , bearUrisIpfs[uniqueNFTIndex]);

        }
    }

    function getChainlinkDataFeedLatestAnswer()public view returns (uint256) {
        uint80 _roundId;
        int256 _price;
        uint256 _updatedAt;
        try priceFeed.latestRoundData() returns (
            uint80 roundId,
            int256 price,
            uint256,
            /* startedAt */
            uint256 updatedAt,
            uint80 /* answeredInRound */
        ) {
            _roundId = roundId;
            _price = price;
            _updatedAt = updatedAt;
        } catch {
            revert PriceFeedDdosed();
        }

        if (_roundId == 0) revert InvalidRoundId();

        if (_updatedAt < block.timestamp - HEARTBEAT) {
            revert StalePriceFeed();
        }

        return uint256(_price);
    }   

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        if(address(this).balance <= 0){
            revert notEnugh();
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function addbull(string memory newbull) external onlyOwner{
        bullUrisIpfs.push(newbull);
    }

    function addbear(string memory newbear) external onlyOwner{
        bearUrisIpfs.push(newbear);
    }

    function setinterval(uint256 newinter)external onlyOwner{
        interval = newinter;
    } 

    function newSub(uint256 sub)external onlyOwner{
        s_subscriptionId = sub;
    }

    function setPriceMint(uint256 newPriceInWei)external onlyOwner{
        mintPriceWei = newPriceInWei ;
    }

    function setFeed(address _feed)external onlyOwner{
        priceFeed = AggregatorV3Interface(_feed);
    }

    function goodBye()external onlyOwner{
        selfdestruct(payable(msg.sender));
    }
    
}

