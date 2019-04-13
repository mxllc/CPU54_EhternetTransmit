#include <iostream>
#include <fstream>
#include <string>
using namespace std;

int main()
{
	ifstream in("input.txt");
	//ofstream out("output.txt");
	for(int i=0;i<32;++i)
	{
		string str;
		in >> str;
		for(int j=0;j<8;++j)
		{

			switch (str[j])
			{
			case '0':
				cout << "0000";
				break;
			case '1':
				cout << "0001";
				break;
			case '2':
				cout << "0010";
				break;
			case '3':
				cout << "0011";
				break;
			case '4':
				cout << "0100";
				break;
			case '5':
				cout << "0101";
				break;
			case '6':
				cout << "0110";
				break;
			case '7':
				cout << "0111";
				break;
			case '8':
				cout << "1000";
				break;
			case '9':
				cout << "1001";
				break;
			case 'A':
				cout << "1010";
				break;
			case 'B':
				cout << "1011";
				break;
			case 'C':
				cout << "1100";
				break;
			case 'D':
				cout << "1101";
				break;
			case 'E':
				cout << "1110";
				break;
			case 'F':
				cout << "1111";
				break;
			default:
				cout << "WA" << endl;
				break;
			}
		}
		cout << endl;
	}
	//out.close();
	in.close();

	return 0;
}