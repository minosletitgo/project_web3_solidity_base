// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC721A: A more gas efficient implementation of ERC721 for batch minting
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721A is Context {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // _currentIndex starts at 1 to avoid zero tokenId confusion
    uint256 private _currentIndex = 1;
    // _burnCounter is used to count burned tokens
    uint256 private _burnCounter;

    // The address of the contract owner
    address private _owner;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
    }

    // Total supply
    function totalSupply() public view returns (uint256) {
        return _currentIndex - _burnCounter - 1;
    }

    // Name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    // Symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the owner of a specific tokenId
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721A: owner query for nonexistent token");
        return _owners[tokenId];
    }

    // Returns the balance of an address
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721A: balance query for the zero address");
        return _balances[owner];
    }

    // Internal mint function
    function _mint(address to, uint256 quantity) internal {
        require(to != address(0), "ERC721A: mint to the zero address");
        require(quantity > 0, "ERC721A: quantity must be greater than zero");

        uint256 startTokenId = _currentIndex;
        _balances[to] += quantity;
        _owners[startTokenId] = to;

        // Update the current index
        _currentIndex += quantity;

        emit Transfer(address(0), to, startTokenId);
    }

    // Batch mint function
    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    // Transfer token
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721A: transfer of token that is not owned");
        require(to != address(0), "ERC721A: transfer to the zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Approval of a tokenId to an address
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721A: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721A: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    // Set approval for all tokens owned by the sender
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "ERC721A: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    // Check if an address is approved for a specific tokenId
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721A: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    // Check if an operator is approved for all tokens of an owner
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Check if a tokenId exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && _owners[tokenId] != address(0);
    }

    // Emit transfer event
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // Emit approval event
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // Emit approval for all event
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}
