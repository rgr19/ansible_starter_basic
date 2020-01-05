# setup.py
import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name='ansible_starter',
    version='0.1',
    scripts=['ansible_starter.sh'],
    author="Robert Grzelka",
    author_email="robert.grzelka@outlook.com",
    description="Bash script for creating fully functional ansible project.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/rgr19/ansible_starter",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: BSD License",
        "Operating System :: OS Independent",
    ],
)