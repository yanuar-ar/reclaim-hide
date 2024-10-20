// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Claims} from "./lib/Claims.sol";

interface IReclaim {
    struct Witness {
        address addr;
        string host;
    }

    function fetchWitnessesForClaim(uint32 epoch, bytes32 identifier, uint32 timestampS)
        external
        view
        returns (Witness[] memory);
}

contract ReclaimHide {
    struct Proof {
        bytes32 hashedClaimInfo;
        Claims.SignedClaim signedClaim;
    }

    address public immutable reclaim;

    constructor(address _reclaim) {
        reclaim = _reclaim;
    }

    function verifyProof(Proof memory proof) public view returns (bool) {
        // create signed claim using claimData and signature.
        require(proof.signedClaim.signatures.length > 0, "No signatures");
        Claims.SignedClaim memory signed = Claims.SignedClaim(proof.signedClaim.claim, proof.signedClaim.signatures);

        // check if the hash from the hashedClaimInfo is equal to the infoHash in the claimData
        require(proof.signedClaim.claim.identifier == proof.hashedClaimInfo);

        // fetch witness list from fetchEpoch(_epoch).witnesses
        IReclaim.Witness[] memory expectedWitnesses = IReclaim(reclaim).fetchWitnessesForClaim(
            proof.signedClaim.claim.epoch, proof.signedClaim.claim.identifier, proof.signedClaim.claim.timestampS
        );

        address[] memory signedWitnesses = Claims.recoverSignersOfSignedClaim(signed);
        // check if the number of signatures is equal to the number of witnesses
        require(
            signedWitnesses.length == expectedWitnesses.length, "Number of signatures not equal to number of witnesses"
        );

        // Check for duplicate witness signatures
        for (uint256 i = 0; i < signedWitnesses.length; i++) {
            for (uint256 j = 0; j < signedWitnesses.length; j++) {
                if (i == j) continue;
                require(signedWitnesses[i] != signedWitnesses[j], "Duplicated Signatures Found");
            }
        }

        // Update awaited: more checks on whose signatures can be considered.
        for (uint256 i = 0; i < signed.signatures.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < expectedWitnesses.length; j++) {
                if (signedWitnesses[i] == expectedWitnesses[j].addr) {
                    found = true;
                    break;
                }
            }
            require(found, "Signature not appropriate");
        }
        return true;
    }

    function hashClaimInfo(string memory provider, string memory parameters, string memory context)
        external
        pure
        returns (bytes32)
    {
        bytes memory serialised = abi.encodePacked(provider, "\n", parameters, "\n", context);
        return keccak256(serialised);
    }
}
