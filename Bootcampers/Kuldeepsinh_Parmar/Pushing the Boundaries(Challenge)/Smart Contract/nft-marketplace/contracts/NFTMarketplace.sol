// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract NFTMarketplace is ERC721, Ownable, ReentrancyGuard, VRFConsumerBaseV2Plus {
    // using VRFV2PlusClient for VRFV2PlusClient.Config;

    // VRFV2PlusClient.Config private s_config;
    uint256 private _tokenIdTracker;
    uint256 private _shardIdTracker;

    uint256 public s_requestId;
    uint256 public s_randomWord;

     // VRF related variables
    bytes32 private s_keyHash;
    uint256 private s_subId;
    uint32 private s_callbackGasLimit;
    uint16 private s_requestConfirmations;
    uint32 private s_numWords;

    struct NFT {
        string name;
        string description;
        string tokenURI;
        bool fractionalized;
        uint256[9] shardIds;
        address artist;
    }

    struct Shard {
        uint256 nftId;
        uint256 price;
        uint256 lastTransactionValue;
        address owner;
        bool forSale;
    }

    uint256[] private _allShardIds;
    mapping(uint256 => uint256) private _shardIdToIndex;
    mapping(uint256 => NFT) private _nfts;
    mapping(uint256 => Shard) private _shards;
    mapping(bytes32 => uint256) private _artistNFTHash;
    mapping(bytes32 => uint256) private _shardHash;
    mapping(bytes32 => address) private _shardOwnerHash;

    uint256 public platformFee = 10; // 1% fee (in basis points)
    uint256 public constant ARTIST_ROYALTY = 40; // 4% royalty (in basis points)

    event NFTMinted(uint256 indexed tokenId, address indexed artist);
    event NFTFractionalized(uint256 indexed tokenId, uint256[9] shardIds);
    event ShardListed(uint256 indexed shardId, uint256 price);
    event ShardSold(uint256 indexed shardId, address indexed seller, address indexed buyer, uint256 price);
    event NFTReconstructed(uint256 indexed tokenId, address indexed reconstructor, uint256 finalValue);
    event RandomnessRequested(uint256 requestId);
    event RandomnessReceived(uint256 requestId, uint256 randomWord);

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    )
        ERC721("FractionalNFT", "FNFT")
        VRFConsumerBaseV2Plus(vrfCoordinator)
        Ownable(msg.sender)
    {
       s_keyHash = keyHash;
        s_subId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;
    }

    function mintAndFractionalize(
        string memory tokenURI,
        string memory nftName,
        string memory nftDescription,
        uint256[9] memory shardPrices
    ) public nonReentrant returns (uint256, uint256[9] memory) {
        uint256 newTokenId = ++_tokenIdTracker;

        _safeMint(msg.sender, newTokenId);

        bytes32 artistNFTHash = keccak256(abi.encodePacked(msg.sender, newTokenId));
        _artistNFTHash[artistNFTHash] = newTokenId;

        uint256[9] memory shardIds;
        for (uint256 i = 0; i < 9; i++) {
            uint256 shardId = ++_tokenIdTracker;
            shardIds[i] = shardId;

            bytes32 shardHash = keccak256(abi.encodePacked(artistNFTHash, shardId));
            _shardHash[shardHash] = shardId;

            bytes32 ownerHash = keccak256(abi.encodePacked(shardHash, msg.sender));
            _shardOwnerHash[ownerHash] = msg.sender;

            _shards[shardId] = Shard({
                nftId: newTokenId,
                price: shardPrices[i],
                lastTransactionValue: 0,
                owner: msg.sender,
                forSale: false
            });

            _safeMint(msg.sender, shardId);

            _shardIdToIndex[shardId] = _allShardIds.length;
            _allShardIds.push(shardId);
        }

        _nfts[newTokenId] = NFT({
            name: nftName,
            description: nftDescription,
            tokenURI: tokenURI,
            fractionalized: true,
            shardIds: shardIds,
            artist: msg.sender
        });

        emit NFTMinted(newTokenId, msg.sender);
        emit NFTFractionalized(newTokenId, shardIds);

        return (newTokenId, shardIds);
    }

    function listShard(uint256 shardId, uint256 price) external {
        require(_shards[shardId].owner == msg.sender, "Not the owner of this shard");
        require(price > 0, "Price must be greater than zero");

        _shards[shardId].price = price;
        _shards[shardId].forSale = true;

        emit ShardListed(shardId, price);

        requestRandomness();
    }

    function buyShard(uint256 shardId) external payable nonReentrant {
        Shard storage shard = _shards[shardId];
        require(shard.forSale, "Shard is not for sale");
        require(msg.value >= shard.price, "Insufficient payment");

        address seller = shard.owner;
        uint256 price = shard.price;

        uint256 platformFeeAmount = (price * platformFee) / 1000;
        uint256 artistRoyalty = (price * ARTIST_ROYALTY) / 1000;
        uint256 sellerAmount = price - platformFeeAmount - artistRoyalty;

        _safeTransfer(seller, msg.sender, shardId, "");
        shard.owner = msg.sender;
        shard.forSale = false;
        shard.lastTransactionValue = price;

        bytes32 shardHash = keccak256(abi.encodePacked(_artistNFTHash[keccak256(abi.encodePacked(_nfts[shard.nftId].artist, shard.nftId))], shardId));
        bytes32 newOwnerHash = keccak256(abi.encodePacked(shardHash, msg.sender));
        _shardOwnerHash[newOwnerHash] = msg.sender;

        payable(owner()).transfer(platformFeeAmount);
        address artist = _nfts[shard.nftId].artist;
        require(artist != address(0), "Artist address not found");
        payable(artist).transfer(artistRoyalty);
        payable(seller).transfer(sellerAmount);

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit ShardSold(shardId, seller, msg.sender, price);

        checkAndReconstructNFT(shardId, msg.sender);
    }

    function checkAndReconstructNFT(uint256 shardId, address buyer) internal {
        uint256 nftId = _shards[shardId].nftId;
        NFT storage nft = _nfts[nftId];

        bool ownsAllShards = true;
        uint256 totalValue = 0;

        for (uint256 i = 0; i < nft.shardIds.length; i++) {
            if (_shards[nft.shardIds[i]].owner != buyer) {
                ownsAllShards = false;
                break;
            }
            totalValue += _shards[nft.shardIds[i]].lastTransactionValue;
        }

        if (ownsAllShards) {
            for (uint256 i = 0; i < nft.shardIds.length; i++) {
                uint256 currentShardId = nft.shardIds[i];
                _burn(currentShardId);

                uint256 indexToRemove = _shardIdToIndex[currentShardId];
                uint256 lastIndex = _allShardIds.length - 1;
                if (indexToRemove != lastIndex) {
                    uint256 lastShardId = _allShardIds[lastIndex];
                    _allShardIds[indexToRemove] = lastShardId;
                    _shardIdToIndex[lastShardId] = indexToRemove;
                }
                _allShardIds.pop();

                delete _shards[currentShardId];
                delete _shardIdToIndex[currentShardId];
            }

            require(nft.artist != address(0), "NFT does not exist");
            _safeTransfer(address(this), buyer, nftId, "");

            nft.fractionalized = false;

            emit NFTReconstructed(nftId, buyer, totalValue);
        }
    }

     function requestRandomness() internal {
        s_requestId = VRFV2PlusClient.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subId,
                requestConfirmations: s_requestConfirmations,
                callbackGasLimit: s_callbackGasLimit,
                numWords: s_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            })
        );
        emit RandomnessRequested(s_requestId);
    }

     function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(requestId == s_requestId, "Wrong requestId");
        require(randomWords.length > 0, "Not enough random words");
        s_randomWord = randomWords[0];
        emit RandomnessReceived(requestId, s_randomWord);
    }

    function getRandomizedListings(uint256 count) external view returns (uint256[] memory) {
        require(count <= _allShardIds.length, "Requested count exceeds available listings");

        uint256[] memory randomizedList = new uint256[](count);
        uint256[] memory indices = new uint256[](_allShardIds.length);

        for (uint256 i = 0; i < _allShardIds.length; i++) {
            indices[i] = i;
        }

        for (uint256 i = 0; i < count; i++) {
            uint256 j = i + (uint256(keccak256(abi.encode(s_randomWord, i))) % (_allShardIds.length - i));
            (indices[i], indices[j]) = (indices[j], indices[i]);
            randomizedList[i] = _allShardIds[indices[i]];
        }

        return randomizedList;
    }

    function getNFTInfo(uint256 tokenId) public view returns (NFT memory) {
        return _nfts[tokenId];
    }

    function getShardInfo(uint256 shardId) public view returns (Shard memory) {
        return _shards[shardId];
    }

    function verifyArtistNFT(address artist, uint256 tokenId) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(artist, tokenId));
        return _artistNFTHash[hash] == tokenId;
    }

    function verifyShardOwnership(uint256 shardId, address owner) public view returns (bool) {
        uint256 nftId = _shards[shardId].nftId;
        address artist = _nfts[nftId].artist;
        bytes32 artistNFTHash = keccak256(abi.encodePacked(artist, nftId));
        bytes32 shardHash = keccak256(abi.encodePacked(artistNFTHash, shardId));
        bytes32 ownerHash = keccak256(abi.encodePacked(shardHash, owner));
        return _shardOwnerHash[ownerHash] == owner;
    }

    function setPlatformFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee cannot exceed 10%");
        platformFee = _fee;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _nfts[tokenId].tokenURI;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
    return _ownerOf(tokenId) != address(0);
}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

        // Override ownership functions
    function owner() public view override(Ownable, VRFConsumerBaseV2Plus) returns (address) {
        return Ownable.owner();
    }

    function transferOwnership(address newOwner) public virtual override(Ownable, VRFConsumerBaseV2Plus) onlyOwner {
        Ownable.transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal override(Ownable, VRFConsumerBaseV2Plus) {
        Ownable.transferOwnership(newOwner);
    }

    // Override onlyOwner modifier
    modifier onlyOwner() override( Ownable, VRFConsumerBaseV2Plus) {
        _checkOwner();
        _;
    }

    // Add this function to resolve the _checkOwner conflict
    function _checkOwner() internal view virtual override(Ownable) {
        Ownable._checkOwner();
    }




}