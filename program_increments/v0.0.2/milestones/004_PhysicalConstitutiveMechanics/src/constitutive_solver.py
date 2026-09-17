"""
Physical Constitutive Mechanics & Fracture Solver for SCR (Milestone 004).
"""
import os
import sys

# Reference the shared canonical module in lib/501_Physics/Material/
LIB_PHYS_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../../../lib/501_Physics/Material"))
if LIB_PHYS_PATH not in sys.path:
    sys.path.insert(0, LIB_PHYS_PATH)

from constitutive_mechanics import ConstitutiveSolver, ElasticModuli, AcousticVelocities
