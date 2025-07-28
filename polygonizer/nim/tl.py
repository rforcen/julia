import ctypes
import os

# Get the directory of the current Python script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Construct the full path to the shared library
# Adjust the library name based on your OS (.so, .dll, .dylib)
if os.name == 'posix': # Linux or macOS
    lib_name = "libtest_export.so"
elif os.name == 'nt': # Windows
    lib_name = "libtest_export.dll"
else:
    raise RuntimeError("Unsupported operating system")

lib_path = os.path.join(script_dir, lib_name)

try:
    # Load the shared library
    test_lib = ctypes.CDLL(lib_path)

    # Define the function signature (optional but highly recommended for type safety)
    # The C function: int getFortyTwo()
    test_lib.getFortyTwo.argtypes = [] # No arguments
    test_lib.getFortyTwo.restype = ctypes.c_int # Returns an integer

    # Call the function
    result = test_lib.getFortyTwo()

    print(f"Python: Result from Nim function getFortyTwo(): {result}")

except OSError as e:
    print(f"Error loading or calling library: {e}")
    print(f"Attempted to load from: {lib_path}")
    print("This often means the shared library file is not found or symbols are not exported.")
    print("  - Check if 'libtest_export.so' (or .dll/.dylib) exists at the specified path.")
    print("  - Run 'nm libtest_export.so | grep getFortyTwo' and ensure it shows 'T' (uppercase) for global export.")
except AttributeError as e:
    print(f"Error: Symbol not found or signature mismatch: {e}")
    print("  - The function 'getFortyTwo' might not be exported or its name is different.")
    print("  - Check 'nm libtest_export.so' output for the exact exported symbol name.")
