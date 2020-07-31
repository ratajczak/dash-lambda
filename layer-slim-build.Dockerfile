FROM lambci/lambda:build-python3.6

COPY ./requirements.txt /tmp/requirements.txt

# Use "--no-compile" here because "--compile" generates suboptimal .pyc files in __pycache__ folders.
RUN pip install \
    --no-cache-dir \
    --no-compile \ 
    --global-option=build_ext \
    --global-option="-j 3" \
    -r /tmp/requirements.txt \
    -t /build/python

WORKDIR /build

RUN printf "Size after installation:\n" > /tmp/size-delta.txt && \
    du -h --max-depth=2 >> /tmp/size-delta.txt

# Generate pyc files, use "-b" to write the byte-code files to their legacy
# locations and names to allow removal of the original .py source files.
# Use "-OO" to remove assert statements, code conditional on __debug__, discard docstrings.
# docs.python.org/3/using/cmdline.html#cmdoption-oo
# docs.python.org/3/library/compileall.html#cmdoption-compileall-b
RUN python -OO -m compileall -q -b ./python

RUN printf "Size after compilation:\n" >> /tmp/size-delta.txt && \
    du -h --max-depth=2 >> /tmp/size-delta.txt

# Strip .so files, delete .py files and -info, doc, tests folders.
RUN find . -type f -name "*.so" -exec strip --strip-all {} + && \
    find . -type f -name "*.py" -exec rm {} + && \
    find . -type d -name "*-info" -exec rm -rf {} + && \
    find . -type d -name doc -exec rm -rf {} + && \
    find . -type d -name tests -exec rm -rf {} + 

# TODO fix duplicates in numpy.libs and scipy/.libs

RUN printf "Size after removing docs, tests, *.py files, *.-info folders and stripping *.so files:\n" >> /tmp/size-delta.txt && \
    du -h --max-depth=2 >> /tmp/size-delta.txt
RUN cat /tmp/size-delta.txt

RUN zip -r9q /tmp/layer.zip *
RUN du -sh /tmp/layer.zip
