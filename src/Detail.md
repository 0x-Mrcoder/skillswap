3bdd51d7701c9f2c11a656c7e826a853b808ffb336e0c98a257dae4652218f9e
0x62127c8ab2145924e51d2cdd1e60863f267a83d0

forge create src/SkillToken.sol:SkillToken \
  --chain 37111 \
  --private-key 3bdd51d7701c9f2c11a656c7e826a853b808ffb336e0c98a257dae4652218f9e \
  --zksync

  forge create src/SkillSwap.sol:SkillSwap \
  --rpc-url https://rpc.testnet.lens.xyz \
  --constructor-args 0x62127c8ab2145924e51d2cdd1e60863f267a83d0 \
  --chain 37111 \
  --private-key 3bdd51d7701c9f2c11a656c7e826a853b808ffb336e0c98a257dae4652218f9e \
  --zksync

  forge script script/DeploySkillSwap.s.sol:DeploySkillSwap \
  --rpc-url https://rpc.testnet.lens.xyz \
  --chain 37111 \
  --private-key 3bdd51d7701c9f2c11a656c7e826a853b808ffb336e0c98a257dae4652218f9e \
  --broadcast


##### 37111
✅  [Success] Hash: 0xd9c8febe8feb360328446d3607abd7c186dce63acea9a0d12394c659f5c01f7a
Contract Address: 0xDEBF0805F101A135201615100573FafEb4bC696a
Block: 3604738
Paid: 0.013081143844352124 ETH (2253228 gas * 5.805512733 gwei)

✅ Sequence #1 on 37111 | Total Paid: 0.013081143844352124 ETH (2253228 gas * avg 5.805512733 gwei)
                                                                                                    



