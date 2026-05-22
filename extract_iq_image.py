import json, base64, os

fname = r"C:\Users\AG\.claude\projects\C--src-akinator\ce67a7dc-42a3-4950-aac6-8458376271cf.jsonl"
out_path = r"C:\src\reflexiq_app\iq_source.png"

found = []
with open(fname, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
            msg = obj.get('message', {})
            content = msg.get('content', [])
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get('type') == 'image':
                        src = block.get('source', {})
                        if src.get('type') == 'base64' and src.get('media_type', '').startswith('image/'):
                            found.append(src['data'])
        except:
            pass

print(f"Found {len(found)} images")
if found:
    data = found[-1]
    with open(out_path, 'wb') as f:
        f.write(base64.b64decode(data))
    print(f"Saved to {out_path}, size: {os.path.getsize(out_path)} bytes")
else:
    print("No images found")
