#!/bin/bash
# ================================================================
#  ENS Resolution Demo — vitalik.eth
#  Just HTTPS calls to a public blockchain.
# ================================================================
ENS_NAME="vitalik.eth"
RPC="https://eth.drpc.org"

# ----------------------------------------------------------------
# STEP 1 — Namehash (pre-computed)
# ENS doesn't use the raw name string — it hashes each label
# recursively so all names share a common on-chain index.
# Verify yours at: https://tools.ens.xyz/check/vitalik.eth
# ----------------------------------------------------------------
NAMEHASH="ee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835"
echo "  Namehash: 0x$NAMEHASH"

# ----------------------------------------------------------------
# STEP 2 — Query the ENS Registry
# Single Global Smart contract that maps every ENS name to its resolver.
# Smart Contract Address : 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
# Function : resolver(bytes32)  →  selector 0x0178b8bf
# ----------------------------------------------------------------
RESOLVER_RAW=$(curl -s -X POST $RPC \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e\",\"data\":\"0x0178b8bf$NAMEHASH\"},\"latest\"],\"id\":1}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])")

RESOLVER="0x${RESOLVER_RAW: -40}"
echo "  Resolver contract: $RESOLVER"

# ----------------------------------------------------------------
# STEP 3 — Query the Resolver for the Content Hash
# The resolver holds the actual records for this name.
# This is the same field an attacker uses to store a C2 IP.
# Function : contenthash(bytes32)  →  selector 0xbc1c58d1
# ----------------------------------------------------------------
RAW=$(curl -s -X POST $RPC \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$RESOLVER\",\"data\":\"0xbc1c58d1$NAMEHASH\"},\"latest\"],\"id\":2}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])")

echo "  $RAW"

# ----------------------------------------------------------------
# STEP 4 — Decode the Result
# The raw hex is ABI-encoded binary with ipfs:// as prefix
# ----------------------------------------------------------------
python3 -c "
import base64

raw      = '$RAW'
data     = raw[2:]
byte_len = int(data[64:128], 16)
content  = data[128:128 + byte_len * 2]
cb       = bytes.fromhex(content)

prefix   = cb[:2].hex()
protocol = 'ipfs' if prefix == 'e301' else ('ipns' if prefix == 'e501' else f'unknown:{prefix}')
cid_bytes = cb[2:]

b32 = base64.b32encode(cid_bytes).decode().lower().rstrip('=')
print(f'  {protocol}://b{b32}')
"
