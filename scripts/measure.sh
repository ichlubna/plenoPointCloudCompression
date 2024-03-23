# First, export the script from blender plenoCompression.blend file to script.py
for s in Buddha Flower Land; do
	for q in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0; do
		blender --background ../plenoCompression.blend --python script.py -- $q $s
	done 
done

