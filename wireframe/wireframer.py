# This program reads an OBJ file and outputs lua code to draw its wireframe.

from sys import argv
import numpy as np

if len(argv) != 2:
    print("usage:")
    print("    python3 %s <file.obj>"%(argv[0]))

fname = argv[1]

vertexes = []
lines = []

def relativize_vertex_index(i):
    if i < 0:
        return len(vertexes) + i + 1
    else:
        return i

def face_orientation(f):
    p1 = vertexes[f[0]-1]
    p2 = vertexes[f[1]-1]
    p3 = vertexes[f[2]-1]

    diff = (p2[1] - p1[1]) * (p3[0] - p2[0]) - (p2[0] - p1[0]) * (p3[1] - p2[1])
    return diff >= 0

with open(fname, "r") as f:
    for line in f:
        line = line.strip()
        if len(line) == 0:
            continue
        splt = line.split(" ")

        if splt[0] == "v":
            vertexes.append((
                float(splt[1].split("/")[0]),
                float(splt[2].split("/")[0]),
                -float(splt[3].split("/")[0])))
        elif splt[0] == "f":

            face = [relativize_vertex_index(int(sp.split("/")[0])) for sp in splt[1:]]
            orientation = face_orientation(face)

            for i in range(len(face) - 1):
                v1 = face[i]
                v2 = face[i + 1]

                if v1 < v2:
                    lines.append((v1, v2))
                else:
                    lines.append((v2, v1))

# Delete repeated lines
lines = list(set(lines))

# Normalize vertexes so that they can be stored as ints
TARGET_RAD = 60
vertexes = np.array(vertexes)
mags = np.sqrt(np.sum(vertexes**2, axis=1))
max_mag = np.max(mags)
vertexes *= TARGET_RAD / max_mag

# Print lua code
print("vertexes = {")
for i in range(vertexes.shape[0]):
    x = int(round(vertexes[i][0]))
    y = int(round(vertexes[i][1]))
    z = int(round(vertexes[i][2]))
    print(" {%d, %d, %d},"%(x, y, z))
print("}")
print("")

print("lines = {")
for i in range(len(lines)):
    v1 = lines[i][0]
    v2 = lines[i][1]
    print(" {%d, %d},"%(v1, v2))
print("}")
print("")

print("function draw_wireframe(angle)")
print(" cosa = cos(angle)")
print(" sina = sin(angle)")
print(" -- compute screen x for all vertices")
print(" for v in all(vertexes) do")
print("  v[4] = cosa*v[1] + sina*v[3]")
print(" end")
print(" -- draw lines (back first, top later)")
print(" for li in all(lines) do")
print("  v1 = vertexes[li[1]]")
print("  v2 = vertexes[li[2]]")
print("  line(v1[4]+64, -v1[2]+100, v2[4]+64, -v2[2]+100, 9)")
print(" end")
print("end")


print("")
print("frame = 0")
print("")
print("function _update()")
print(" frame += 1")
print("end")
print("")
print("function _draw()")
print(" cls(0)")
print(" draw_wireframe(frame*0.01)")
print("end")
