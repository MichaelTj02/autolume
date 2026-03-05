#!/usr/bin/env python3
"""
Command-line wrapper for train.py
This allows training from command line by properly setting up queue/reply objects.
"""

import queue
import sys
from train import main

if __name__ == "__main__":
    # Import the click command from train module
    import train
    
    # Get the click command object (clickmain decorated function)
    cmd = train.clickmain
    
    # Parse arguments using click's context
    try:
        ctx = cmd.make_context('train_wrapper', sys.argv[1:])
        kwargs = ctx.params
    except SystemExit:
        # Click will call sys.exit() on help or errors, catch it
        sys.exit(0)
    
    # Create queue and reply objects that main() expects
    cmd_queue = queue.Queue()
    reply_queue = queue.Queue()
    
    # Put kwargs in queue
    cmd_queue.put(kwargs)
    
    # Call main with proper arguments
    try:
        main(cmd_queue, reply_queue)
    except KeyboardInterrupt:
        print("\nTraining interrupted by user")
        sys.exit(1)
