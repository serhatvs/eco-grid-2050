import pptx
import sys
sys.stdout.reconfigure(encoding='utf-8')

prs = pptx.Presentation(r'C:\Users\serhat\Desktop\Eco-Grid-2050-Hackathon-Sunumu.pptx')
slide_width = prs.slide_width
slide_height = prs.slide_height
print(f'Slide dimensions: {slide_width} x {slide_height} ({slide_width/914400:.2f}\" x {slide_height/914400:.2f}\")')

for idx, slide in enumerate(prs.slides):
    print(f'\n=== SLIDE {idx+1} ===')
    shapes = list(slide.shapes)
    for s_idx, shape in enumerate(shapes):
        t = shape.text_frame.text.strip().replace('\n', ' // ') if shape.has_text_frame else ''
        print(f'  [{s_idx}] id={shape.shape_id} name="{shape.name}" type={shape.shape_type} pos=({shape.left}, {shape.top}, {shape.width}, {shape.height}) text="{t[:60]}"')
    
    # Check bounding box overlaps
    for i in range(len(shapes)):
        for j in range(i+1, len(shapes)):
            s1 = shapes[i]
            s2 = shapes[j]
            # Ignore background lines or tiny shapes
            if s1.width == 0 or s1.height == 0 or s2.width == 0 or s2.height == 0:
                continue
            # Bounding boxes
            r1 = (s1.left, s1.top, s1.left + s1.width, s1.top + s1.height)
            r2 = (s2.left, s2.top, s2.left + s2.width, s2.top + s2.height)
            # Intersection
            ix1 = max(r1[0], r2[0])
            iy1 = max(r1[1], r2[1])
            ix2 = min(r1[2], r2[2])
            iy2 = min(r1[3], r2[3])
            if ix1 < ix2 and iy1 < iy2:
                # Overlap!
                t1 = s1.text_frame.text.strip()[:30] if s1.has_text_frame else '(Picture/Shape)'
                t2 = s2.text_frame.text.strip()[:30] if s2.has_text_frame else '(Picture/Shape)'
                print(f'    ⚠️ OVERLAP: [{s1.name}] "{t1}" and [{s2.name}] "{t2}"')
