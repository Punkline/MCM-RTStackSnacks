# MCM-RTStackSnacks

RT Stack Snacks is a module for MCM that enables a unique method of allocating globally accessible variables using a series of files kept in the MCM directory. These allocations may be thought of as static, but do not take up space in the DOL or in the dynamic memory heap -- and are initially zeroed out. They may be used to house data variables as needed for large code projects in a way that makes them very easy to define and use from multiple Melee codes.
