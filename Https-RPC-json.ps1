# ================================================================
#  ENS Resolution Demo — vitalik.eth
#  Just HTTPS calls to a public blockchain.
# ================================================================

$ENS_NAME = "vitalik.eth"
$RPC      = "https://eth.drpc.org"
# ----------------------------------------------------------------
# STEP 1 — Namehash (pre-computed)
# ENS doesn't use the raw name string — it hashes each label
# recursively so all names share a common on-chain index.
# Verify yours at: https://tools.ens.xyz/check/vitalik.eth
# ----------------------------------------------------------------
$namehash = "ee6c4522aab0003e8d14cd40a6af439055fd2577951148c14b6cea9a53475835"
Write-Host "  Namehash: 0x$namehash" -ForegroundColor Green
# ----------------------------------------------------------------
# STEP 2 — Query the ENS Registry
# Single Global Smart contract that maps every ENS name to its resolver.
# Smart Contract Address : 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
# Function : resolver(bytes32)  →  selector 0x0178b8bf
# ----------------------------------------------------------------
$body1 = '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e","data":"0x0178b8bf' + $namehash + '"},"latest"],"id":1}'
$resp1 = Invoke-RestMethod -Uri $RPC -Method POST -ContentType "application/json" -Body $body1
$resolverRaw  = $resp1.result
$resolverAddr = "0x" + $resolverRaw.Substring($resolverRaw.Length - 40)
Write-Host "  Resolver contract: $resolverAddr" -ForegroundColor Green
# ----------------------------------------------------------------
# STEP 3 — Query the Resolver for the Content Hash
# The resolver holds the actual records for this name.
# This is the same field an attacker uses to store a C2 IP.
# Function : contenthash(bytes32)  →  selector 0xbc1c58d1
# ----------------------------------------------------------------
$body2 = '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"' + $resolverAddr + '","data":"0xbc1c58d1' + $namehash + '"},"latest"],"id":2}'
$resp2 = Invoke-RestMethod -Uri $RPC -Method POST -ContentType "application/json" -Body $body2

$rawHex = $resp2.result
Write-Host "  $rawHex" -ForegroundColor Yellow


# ----------------------------------------------------------------
# STEP 4 — Decode the Result
# The raw hex is ABI-encoded binary with ipfs:// as prefix
# ----------------------------------------------------------------
$data       = $rawHex.Substring(2)           # strip 0x
$lenHex     = $data.Substring(64, 64)        # bytes 32-63 = length field
$byteLen    = [Convert]::ToInt32($lenHex.TrimStart('0'), 16)
$contentHex = $data.Substring(128, $byteLen * 2)  # exact content bytes

# Convert hex string to byte array
$contentBytes = @()
for ($i = 0; $i -lt $contentHex.Length; $i += 2) {
    $contentBytes += [Convert]::ToByte($contentHex.Substring($i, 2), 16)
}
# Read multicodec prefix (2 bytes)
$prefix = "$($contentBytes[0].ToString('x2'))$($contentBytes[1].ToString('x2'))"
$protocol = switch ($prefix) {
    "e301" { "ipfs" }
    "e501" { "ipns" }
    default { "unknown:0x$prefix" }
}
# CID bytes are everything after the 2-byte prefix
$cidBytes = $contentBytes[2..($contentBytes.Length - 1)]
# Base32 encode (RFC 4648, no padding, lowercase, with 'b' multibase prefix)
$b32chars  = "abcdefghijklmnopqrstuvwxyz234567"
$bits      = ""
foreach ($b in $cidBytes) {
    $bits += [Convert]::ToString($b, 2).PadLeft(8, '0')
}
# Pad bits to multiple of 5
while ($bits.Length % 5 -ne 0) { $bits += "0" }
$b32 = ""
for ($i = 0; $i -lt $bits.Length; $i += 5) {
    $idx  = [Convert]::ToInt32($bits.Substring($i, 5), 2)
    $b32 += $b32chars[$idx]
}

$decoded = "$protocol`://b$b32"
Write-Host "  $decoded" -ForegroundColor Green
Write-Host ""
Write-Host "  Opens at: https://vitalik.eth.limo" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Stored on the Ethereum blockchain." -ForegroundColor DarkGray
Write-Host "  No registrar can seize it. No court order removes it." -ForegroundColor DarkGray
Write-Host "  An attacker swaps this for a C2 IP in one transaction." -ForegroundColor DarkGray
Write-Host ""
