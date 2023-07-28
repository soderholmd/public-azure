# P2S VPN Calculator

This Excel spreadsheet helps you figure out how to price an Azure VPN gateway for P2S connections.

The way the pricing calculator works at the moment, it talks about how many hours your gateway is provisioned (730 hours/month), but also how many users are connected for 730 hours. This gets complicated if your users are only connected some of the time, as you then have to figure out how many 730-hour-a-month-equivalent users are connected (e.g.730 users connected 50% of the time = 365 connected users/month).

This spreadsheet is intended to help with that calculation. You enter how many users are connected during a given 1-hour block over a weekday/weekend, and it figures out how many 730-hour-equivalent users that is. You then take that information and enter it into the pricing calculator to get a reasonably accurate price.

The bandwidth costs may not be 100% correct unless you can really delve into how much is ingress and how much is egress, but should give you a rough order of magnitude indication of what to expect.

As usual this calculator comes with no guarantees or official support, and should be validated with your own calculations. It's just a shortcut to help use the Azure pricing calculator.
