from std.python import Python

def main() raises:
    print("Testing Python import in Mojo")
    var math = Python.import_module("math")
    print(math.sqrt(16))
