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
    
    # Add default values for parameters not in click options but needed by main()
    if 'fps' not in kwargs:
        kwargs['fps'] = 10  # Default fps value
    if 'skip_preprocessing' not in kwargs:
        kwargs['skip_preprocessing'] = True  # Default skip_preprocessing value
    
    # Fix resolution parsing - click parses tuple type incorrectly when given as string
    if 'resolution' in kwargs and kwargs['resolution'] is not None:
        if isinstance(kwargs['resolution'], tuple):
            # Click parsed "(512,512)" as tuple of individual characters
            # Reconstruct the tuple properly
            try:
                # Check if it's a tuple of single characters (click's tuple parsing bug)
                if len(kwargs['resolution']) > 2 and all(isinstance(x, str) and len(x) == 1 for x in kwargs['resolution']):
                    # Reconstruct from string: join chars and parse
                    res_str = ''.join(kwargs['resolution'])
                    if res_str.startswith('(') and res_str.endswith(')'):
                        parts = res_str[1:-1].split(',')
                        kwargs['resolution'] = tuple(int(x.strip()) for x in parts)
                elif all(isinstance(x, (str, int)) for x in kwargs['resolution']):
                    # Try to convert string numbers to ints
                    kwargs['resolution'] = tuple(int(x) if isinstance(x, str) and x.isdigit() else x for x in kwargs['resolution'])
            except (ValueError, TypeError):
                pass  # Keep original if parsing fails
    
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
