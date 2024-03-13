# Source https://stackoverflow.com/questions/60506331/conversion-of-binary-lidar-data-bin-to-point-cloud-data-pcd-format
import open3d as o3d
import struct
import numpy as np
size_float = 4
list_pcd = []
with open (sys.argv[1], "rb") as f:
    byte = f.read(size_float*4)
    while byte:
        x,y,z,intensity = struct.unpack("ffff", byte)
        list_pcd.append([x, y, z])
        byte = f.read(size_float*4)
np_pcd = np.asarray(list_pcd)
pcd = o3d.geometry.PointCloud()
v3d = o3d.utility.Vector3dVector
pcd.points = v3d(np_pcd)
o3d.io.write_point_cloud(sys.argv[2], pcd)
