import unittest

class TestFunctionF(unittest.TestCase):
    def test_empty_string(self):
        self.assertEqual(f(''), {})
    
    def test_single_character(self):
        self.assertEqual(f('a'), {'a': 1})
    
    def test_multiple_characters(self):
        self.assertEqual(f('abca'), {'a': 2, 'b': 1, 'c': 1})

    def test_repeated_characters(self):
        self.assertEqual(f('aaaa'), {'a': 4})

if __name__ == '__main__':
    unittest.main()
