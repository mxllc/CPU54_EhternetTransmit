#include <iostream>
#include <fstream>
#include <string>
using namespace std;

int main()
{
	ifstream in("input.txt");
	ofstream out("output.txt");
	for (int i = 0; i<16; ++i)
	{
		string str;
		in >> str;
		string substr1 = str.substr(0, 8);
		string substr2 = str.substr(8, 8);
		out << substr1 << endl << substr2 << endl;
	}
	out.close();
	in.close();

	return 0;
}