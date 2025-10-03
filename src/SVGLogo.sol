// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SVGLogo Contract
/// @notice A simple contract that stores and returns base64 encoded SVG logo data for ERC20 tokens
contract SVGLogo {
    string private _svgData;

    /// @notice Constructor to set the SVG data
    /// @param svgData The SVG data as a string (should include <svg> tags)
    constructor(string memory svgData) {
        _svgData = svgData;
    }

    /// @notice Returns the stored SVG data
    /// @return The SVG data as a string
    function getSVG() external view returns (string memory) {
        return _svgData;
    }

    /// @notice Returns base64 encoded SVG data with proper MIME type for token URI
    /// @return Base64 encoded SVG data with data URI prefix
    function tokenURI() external view returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", base64Encode(bytes(_svgData))));
    }

    /// @notice Base64 encode function for bytes
    /// @param data The data to encode
    /// @return Base64 encoded string
    function base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Base64 characters: A-Z, a-z, 0-9, +, /
        bytes memory chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        uint256 dataLength = data.length;
        uint256 encodedLen = 4 * ((dataLength + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        uint256 i = 0;
        uint256 j = 0;

        // Process complete 3-byte chunks
        while (i + 3 <= dataLength) {
            uint8 b1 = uint8(data[i]);
            uint8 b2 = uint8(data[i + 1]);
            uint8 b3 = uint8(data[i + 2]);

            uint32 n = (uint32(b1) << 16) | (uint32(b2) << 8) | uint32(b3);

            result[j] = chars[(n >> 18) & 0x3F];
            result[j + 1] = chars[(n >> 12) & 0x3F];
            result[j + 2] = chars[(n >> 6) & 0x3F];
            result[j + 3] = chars[n & 0x3F];

            i += 3;
            j += 4;
        }

        // Handle remaining bytes
        uint256 remaining = dataLength - i;
        if (remaining == 1) {
            uint8 b1 = uint8(data[i]);
            uint16 n = (uint16(b1) << 4);

            result[j] = chars[(n >> 6) & 0x3F];
            result[j + 1] = chars[n & 0x3F];
            result[j + 2] = '=';
            result[j + 3] = '=';
        } else if (remaining == 2) {
            uint8 b1 = uint8(data[i]);
            uint8 b2 = uint8(data[i + 1]);
            uint32 n = (uint32(b1) << 10) | (uint32(b2) << 2);

            result[j] = chars[(n >> 12) & 0x3F];
            result[j + 1] = chars[(n >> 6) & 0x3F];
            result[j + 2] = chars[n & 0x3F];
            result[j + 3] = '=';
        }

        return string(result);
    }
}
