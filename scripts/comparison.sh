# The first argument is the point cloud file pcd and second is the same file as ply
# https://github.com/google/draco
DRACO="/home/ichlubna/Workspace/draco-main/build/"
PCC="/home/ichlubna/Workspace/Real-Time-Spatio-Temporal-LiDAR-Point-Cloud-Compression/src"
IPDAE="https://github.com/I2-Multimedia-Lab/IPDAE"

OUT=./output
mkdir -p $OUT
DECOMPRESSED=$OUT/decompressed
COMPRESSED=$OUT/compressed

PCD_DIR=$OUT/pcd
mkdir -p $PCD_DIR
cp $1 $PCD_DIR/

PLY_DIR=$OUT/ply
mkdir -p $PLY_DIR
cp $2 $PLY_DIR/

$DRACO/draco_encoder --skip NORMAL --skip TEX_COORD --skip GENERIC -qp 8 -cl 10 -point_cloud -i $2 -o $COMPRESSED/draco.drc
$DRACO/draco_decoder -i $OUT/draco.drc - $DECOMPRESSED/draco.ply

python ../external/pcd2bin.py pcd2bin.py --pcd_path=$PCD_DIR --bin_path=./$PCD_DIR --file_name=bin
$PCC/pcc_encoder --path ../data --file $PCD_DIR/bin_00000.bin -p 0.18 -y 0.45 -f binary -l 4 -t 0.5 --out $COMPRESSED/pcc.tar.gz
$PCC/pcc_decoder -p 0.18 -y 0.45 -f binary -l 4 --file $COMPRESSED/pcc.tar.gz
python ../external/bin2pcd.py 0000000000.bin $DECOMPRESSED/pcc.pcd

PLY_ABS=$(pwd $2)
IPDAE_COMP=$COMPRESSED/ipdae
IPDAE_COMP_ABS=$(pwd $IPDAE_COMP)
mkdir -p $IPDAE_COMP
cd $IPDAE
python compress.py  $PLY_ABS $IPDAE_COMP_ABS './model/K256' --K 256
# all versions and K must match the model name
python decompress.py  $IPDAE_COMP_ABS './data/ModelNet40_K256_decompressed' './model/K256' --K 256

cd -

