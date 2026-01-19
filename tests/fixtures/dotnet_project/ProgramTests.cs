using Xunit;

public class ProgramTests
{
    [Fact]
    public void TestAdd()
    {
        Assert.Equal(8, Program.Add(5, 3));
        Assert.Equal(0, Program.Add(0, 0));
        Assert.Equal(-5, Program.Add(-2, -3));
    }
}
