// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] selectors;
        uint16 facetPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // facet address => selectors and facet position
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // list of facet addresses
        address[] facetAddresses;
        // contract owner
        address contractOwner;
        // supported interfaces per ERC-165
        mapping(bytes4 => bool) supportedInterfaces;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // Internal cut mechanics
    function addFunctions(address facetAddress, bytes4[] memory selectors) internal {
        require(selectors.length > 0, "LibDiamond: No selectors to add");
        DiamondStorage storage ds = diamondStorage();
        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[facetAddress];
        if (ffs.selectors.length == 0) {
            ffs.facetPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(facetAddress);
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            bytes4 selector = selectors[i];
            require(ds.selectorToFacetAndPosition[selector].facetAddress == address(0), "LibDiamond: Selector exists");
            ffs.selectors.push(selector);
            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: facetAddress,
                selectorPosition: uint16(ffs.selectors.length - 1)
            });
        }
    }

    function replaceFunctions(address facetAddress, bytes4[] memory selectors) internal {
        require(selectors.length > 0, "LibDiamond: No selectors to replace");
        DiamondStorage storage ds = diamondStorage();
        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[facetAddress];
        if (ffs.selectors.length == 0) {
            ffs.facetPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(facetAddress);
        }
        for (uint256 i = 0; i < selectors.length; i++) {
            bytes4 selector = selectors[i];
            address oldFacet = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacet != address(0), "LibDiamond: Selector does not exist");
            require(oldFacet != facetAddress, "LibDiamond: Replace with same facet");
            _removeFunction(oldFacet, selector);
            ffs.selectors.push(selector);
            ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition({
                facetAddress: facetAddress,
                selectorPosition: uint16(ffs.selectors.length - 1)
            });
        }
    }

    function removeFunctions(address facetAddress, bytes4[] memory selectors) internal {
        facetAddress; // silence unused var
        require(selectors.length > 0, "LibDiamond: No selectors to remove");
        DiamondStorage storage ds = diamondStorage();
        for (uint256 i = 0; i < selectors.length; i++) {
            _removeFunction(ds.selectorToFacetAndPosition[selectors[i]].facetAddress, selectors[i]);
        }
    }

    function _removeFunction(address facetAddress, bytes4 selector) private {
        DiamondStorage storage ds = diamondStorage();
        FacetFunctionSelectors storage ffs = ds.facetFunctionSelectors[facetAddress];
        require(ffs.selectors.length > 0, "LibDiamond: Facet has no selectors");

        // swap and pop selector
        uint256 selectorPos = ds.selectorToFacetAndPosition[selector].selectorPosition;
        uint256 lastPos = ffs.selectors.length - 1;
        if (selectorPos != lastPos) {
            bytes4 lastSelector = ffs.selectors[lastPos];
            ffs.selectors[selectorPos] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].selectorPosition = uint16(selectorPos);
        }
        ffs.selectors.pop();
        delete ds.selectorToFacetAndPosition[selector];

        // remove facet address if no selectors remain
        if (ffs.selectors.length == 0) {
            uint256 lastFacetPos = diamondStorage().facetAddresses.length - 1;
            uint256 facetPos = ffs.facetPosition;
            if (facetPos != lastFacetPos) {
                address lastFacetAddr = diamondStorage().facetAddresses[lastFacetPos];
                diamondStorage().facetAddresses[facetPos] = lastFacetAddr;
                diamondStorage().facetFunctionSelectors[lastFacetAddr].facetPosition = uint16(facetPos);
            }
            diamondStorage().facetAddresses.pop();
            delete diamondStorage().facetFunctionSelectors[facetAddress].facetPosition;
        }
    }
}


