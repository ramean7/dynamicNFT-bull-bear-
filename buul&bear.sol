// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, AutomationCompatible,Ownable {
    using Counters for Counters.Counter;

    error err();
    error  invalaidroundId();    
    error timePast();

    Counters.Counter public tokenIdCounter;
    AggregatorV3Interface public  priceFeed;   
    uint256 private constant HEARTBIT = 86400;
    uint256 interval;
    uint256 lastTimeStamp ;
    uint256 lastPrice ;

    string[] bullUrisIpfs = [        
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json"        
    ];

    string[] bearUrisIpfs = [        
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json"        
    ];

    constructor(address _priceFeed,uint256 _interval)
        ERC721("bull&bear", "BB")
        Ownable(msg.sender)
    {
        priceFeed = AggregatorV3Interface(_priceFeed);
        lastPrice = getChainlinkDataFeedLatestAnswer();
        interval = _interval;
    }

    function safeMint()
        public
        onlyOwner
        returns (uint256)
    {
        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
        return tokenId;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /*performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

    }   

    function performUpkeep(bytes calldata /* performData */ ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp; 

            uint price = getChainlinkDataFeedLatestAnswer();

            if(price == lastPrice){
                return;
            }

            if(price < lastPrice){
                bear();

            }

            if(price > lastPrice){
                bull();
            }

            lastPrice = price;
        }            
    }        

    function bull()internal{
        for(uint i=0 ; i< tokenIdCounter.current(); i++){
            _setTokenURI(i,bullUrisIpfs[0]);
        }
    }

    function bear()internal{
        for(uint i = 0; i < tokenIdCounter.current(); i++){
            _setTokenURI(i , bearUrisIpfs[0]);

        }
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }
    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (uint256) {
        uint80 _roundId; 
        int256 _answer;
        uint256 _updatedAt;
        try priceFeed.latestRoundData() returns(
            uint80 roundId,
            int256 answer,
            uint256, /*startedAt*/
            uint256 updatedAt,
            uint80 /*answeredInRound*/
        ){
            _roundId=roundId;
            _answer=answer;
            _updatedAt=updatedAt;
        }catch {
            revert err();
        }
        if(_roundId == 0){
            revert invalaidroundId();
        }
        if(_updatedAt < block.timestamp - HEARTBIT){
            revert timePast();
        }
        return uint256(_answer);
    }

    // The following functions are overrides required by Solidity.

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
}
