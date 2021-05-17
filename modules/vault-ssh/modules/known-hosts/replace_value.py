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

updated=False
for line in fileinput.input([filename], inplace=True):
    if line.strip().startswith(args.strings[0]):
        line = '{}{}\n'.format( args.strings[0], args.strings[1] )
        print( "Updated line:" )
        print( line )
        updated=True
    sys.stdout.write(line)

if updated:
    print( "Updated key/value: {}{} in {}".format( args.strings[0], args.strings[1], filename ) )
else:
    raise Exception( "ERROR: did not update key/value: {}{} in {}".format( args.strings[0], args.strings[1], filename ) )
