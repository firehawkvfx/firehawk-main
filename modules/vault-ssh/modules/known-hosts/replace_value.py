import argparse
import sys
import fileinput

parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('strings', metavar='S', type=str, nargs=2,
                    help='The key ( eg: my_key= ) and value ( eg: somevalue ) to replace any existing value with.')
parser.add_argument("-f", "--file", type=str,
                    help="Set file to search and replace")

args = parser.parse_args()
filename=args.file

starts_with = args.strings[0]
append = args.strings[1]

print( "Find line that starts with: {}")
print( "Change to: {}{}".format( starts_with, append ) )

updated=False
for line in fileinput.input([filename], inplace=True):
    if line.strip().startswith(starts_with):
        line = '{}{}\n'.format( starts_with, append )
        print( "\nUpdated line:" )
        print( line )
        print()
        updated=True
    else:
        print( "Original line: {}".format( line ) )
    sys.stdout.write(line)

if updated:
    print( "Updated key/value: {}{} in {}".format( starts_with, append, filename ) )
else:
    raise Exception( "ERROR: did not update key/value: {}{} in {}".format( starts_with, append, filename ) )
