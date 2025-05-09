using namespace System.Collections
using namespace System.Collections.Generic

class TestClass {
    hidden [String] $_Value
    TestClass([String]$Value) { $this._Value = $Value }
    [Bool] Equals($Test, [StringComparison]$StringComparison) {
        return $this._Value.Equals([String]$Test._Value, $StringComparison)
    }
    [Bool] Equals($Test) {
        return $this.Equals($Test, [StringComparison]::CurrentCultureIgnoreCase)
    }
}

$a1Lower = [TestClass]'a'
$b1Lower = [TestClass]'b'
$a2Lower = [TestClass]'a'
$a2Upper = [TestClass]'A'

$a1Lower -eq  $b1Lower # False
$a1Lower -eq  $a2Lower # True
$a1Lower -eq  $a2Upper # True

$a1Lower -ceq $a2Lower # True
$a1Lower -ceq $a2Upper # True (expected false)
