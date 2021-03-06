/*******************************************************************************

    Verifies behaviour of turtle.env.Dht helpers that expect running tested
    application

    Copyright:
        Copyright (c) 2016-2017 sociomantic labs GmbH. All rights reserved.

    License:
        Boost Software License Version 1.0. See LICENSE.txt for details.

*******************************************************************************/

module test.env.main;

import ocean.transition;

import turtle.runner.Runner;
import turtle.TestCase;
import turtle.env.Dht;

int main ( istring[] args )
{
    auto runner = new TurtleRunner!(MyTurtleTests)("dhtapp", "",
        "turtle");
    return runner.main(args);
}

class MyTurtleTests : TurtleRunnerTask!(TestedAppKind.Daemon)
{
    override protected void configureTestedApplication ( out double delay,
        out istring[] args, out istring[istring] env )
    {
        delay = 0.05;
        args  = null;
        env   = null;
    }

    override public void prepare ( )
    {
        Dht.initialize();
        dht.start("127.0.0.1", 0);
        dht.genConfigFiles(this.context.paths.sandbox ~ "/etc");
    }

    override public void reset ( )
    {
        dht.clear();
    }
}

class ExpectRecordChange_Missing : TestCase
{
    import ocean.core.Test;

    override public Description description ( )
    {
        return Description("dht.expectRecordChange: no initial record");
    }

    override public void run ( )
    {
        dht.put("test_channel1", 0xBEE, "bzzzzz"[]);
        dht.expectRecordChange("test_channel2", 0xBEE);
        test!("==")(dht.get("test_channel2", 0xBEE), "bzzzzz"[]);
    }
}

class ExpectRecordChange_Replaced : TestCase
{
    import ocean.core.Test;

    override public Description description ( )
    {
        return Description("dht.expectRecordChange: some initial record");
    }

    override public void run ( )
    {
        dht.put("test_channel1", 0xBEE, "bzzzzz"[]);
        dht.put("test_channel2", 0xBEE, "meow"[]);
        dht.expectRecordChange("test_channel2", 0xBEE);
        test!("==")(dht.get("test_channel2", 0xBEE), "bzzzzz"[]);
    }
}

class ExpectRecordChange_Timeout : TestCase
{
    import ocean.core.Test;

    override public Description description ( )
    {
        return Description("dht.expectRecordChange: timeout");
    }

    override public void run ( )
    {
        testThrown!(TestException)(
            dht.expectRecordChange("whatever", 0xAAA, 0.1)
        );
    }
}

class ExpectRecordCondition : TestCase
{
    import ocean.core.Test;

    override public Description description ( )
    {
        return Description("dht.expectRecordCondition: success");
    }

    override public void run ( )
    {
        dht.put("test_channel1", 0xBEE, "bzzzzz"[]);
        dht.expectRecordCondition("test_channel2", 0xBEE,
            ( in void[] record )
            {
                return (cast(cstring) record) == "bzzzzz";
            }
        );
    }
}

class ExpectRecordCondition_Timeout : TestCase
{
    import ocean.core.Test;

    override public Description description ( )
    {
        return Description("dht.expectRecordCondition: timeout");
    }

    override public void run ( )
    {
        testThrown!(TestException)(
            dht.expectRecordCondition("whatever", 0xAAA,
                ( in void[] record ) { return false; }, 0.1)
        );
    }
}
