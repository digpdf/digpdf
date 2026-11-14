"""on_pypi.py SHA256SUMS PYPI.json: every wheel SHA256SUMS names is among the files PyPI lists for the version
(PYPI.json is https://pypi.org/pypi/digpdf/VERSION/json), with the same SHA-256, and PyPI lists no other file.
Exit code 0 when so, 1 with a line for each thing that is not."""
import json
import sys


def main(sums_path, pypi_path):
    wanted = {}
    with open(sums_path, encoding="utf-8") as f:
        for line in f:
            digest, name = line.split()
            if name.endswith(".whl"):
                wanted[name] = digest.lower()
    with open(pypi_path, encoding="utf-8") as f:
        listed = {u["filename"]: u["digests"]["sha256"].lower() for u in json.load(f)["urls"]}
    wrong = []
    for name, digest in sorted(wanted.items()):
        if name not in listed:
            wrong.append("not on PyPI: %s" % name)
        elif listed[name] != digest:
            wrong.append("on PyPI with another hash: %s" % name)
    for name in sorted(set(listed) - set(wanted)):
        wrong.append("on PyPI and not named by the tag: %s" % name)
    for line in wrong:
        print(line)
    if not wrong:
        print("PyPI holds the %d wheels with the hashes the tag names" % len(wanted))
    return 1 if wrong or not wanted else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
