pyenv local 3.11.9
set -x
# The first argument is the point cloud file pcd and second is the same file in ply format
# https://github.com/google/draco
DRACO="/home/ichlubna/Workspace/draco-main/build/"
# https://github.com/horizon-research/Real-Time-Spatio-Temporal-LiDAR-Point-Cloud-Compression
PCC="/home/ichlubna/Workspace/Real-Time-Spatio-Temporal-LiDAR-Point-Cloud-Compression/src"
# https://github.com/I2-Multimedia-Lab/IPDAE
IPDAE="/home/ichlubna/Workspace/IPDAE/"
# https://adioshun.gitbooks.io/pcl/content/Tutorial/Octree/point-cloud-compression-PCL-Cpp.html
PCL="/home/ichlubna/Workspace/plenoPointCloudCompression/scripts/pcl"
# https://github.com/mmspg/pcc-geo-slicing
GEOSLICE="/home/ichlubna/Workspace/pcc-geo-slicing/"
# https://github.com/cnr-isti-vclab/corto
CORTO="/home/ichlubna/Workspace/corto/build"

OUT=./output
OUT_ABS=$(realpath $OUT)
mkdir -p $OUT
DECOMPRESSED=$OUT/decompressed
COMPRESSED=$OUT/compressed
mkdir -p $COMPRESSED
mkdir -p $DECOMPRESSED

PCD_DIR=$OUT/pcd
mkdir -p $PCD_DIR
cp $1 $PCD_DIR/

PLY_DIR=$OUT/ply
mkdir -p $PLY_DIR
cp $2 $PLY_DIR/


$DRACO/draco_encoder --skip NORMAL --skip TEX_COORD --skip GENERIC -qp 8 -cl 10 -point_cloud -i $2 -o $COMPRESSED/draco.drc
$DRACO/draco_decoder -i $COMPRESSED/draco.drc -o $DECOMPRESSED/draco.ply

BIN=$OUT/bin
mkdir -p $BIN
python ../external/pcd2bin.py --pcd_path $PCD_DIR --bin_path $BIN --file_name bin
$PCC/pcc_encoder --path $BIN --file bin_00000.bin -p 0.18 -y 0.45 -f binary -l 4 -t 0.5 --out $COMPRESSED/pcc.tar.gz
$PCC/pcc_decoder -p 0.18 -y 0.45 -f binary -l 4 --file $COMPRESSED/pcc.tar.gz
python ../external/bin2pcd.py ./bin_00000.bin $DECOMPRESSED/pcc.pcd
rm ./bin_00000.bin

PLY_ABS=$(realpath $2)
IPDAE_COMP="$COMPRESSED/ipdae"
IPDAE_COMP_ABS=$(realpath $IPDAE_COMP)
DECOMP_ABS=$(realpath $DECOMPRESSED)
mkdir -p $IPDAE_COMP
cd $IPDAE
python compress.py $PLY_ABS $IPDAE_COMP_ABS './model/K64' --K 64
# all versions and K must match the model name
python decompress.py $IPDAE_COMP_ABS $DECOMP_ABS/ipdae './model/K64' --K 64
cd -

$PCL/pcl $1 $COMPRESSED/pcl.bin $DECOMPRESSED/pcl.pcd

# The model must be in the positive quadrant of the space, must be big enough (relative to resolution), colors must be baked in attributes
PLY_DIR_ABS=$(realpath $PLY_DIR)
GEOSLICE_COMP="$COMPRESSED/geoslice"
mkdir -p $GEOSLICE_COMP
GEOSLICE_COMP_ABS=$(realpath $GEOSLICE_COMP)
GEOSLICE_DECOMP="$DECOMPRESSED/geoslice"
mkdir -p $GEOSLICE_DECOMP
GEOSLICE_DECOMP_ABS=$(realpath $GEOSLICE_DECOMP)
cd $GEOSLICE
python point_cloud_compression_slice_conditioning.py --experiment 'a0.6_res_t64_Slice_cond_160-10_400' --model_path 'models/' compress --adaptive --resolution 64 --input_glob "$PLY_DIR_ABS/*.ply" --output_dir $GEOSLICE_COMP_ABS
python point_cloud_compression_slice_conditioning.py --experiment 'a0.6_res_t64_Slice_cond_160-10_400' --model_path 'models/' decompress --input_dir $GEOSLICE_COMP_ABS --output_dir $GEOSLICE_DECOMP_ABS
cd -

$CORTO/corto $2 -o $COMPRESSED/corto.crt -P $DECOMPRESSED/corto.ply
