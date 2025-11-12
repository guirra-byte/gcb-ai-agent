"""
Agents module for document analysis and information extraction.

This module contains all AI agents used for extracting structured information
from documents. Each agent is specialized for a specific type of extraction task.
"""

from .contract_information_agent import ContractInformationAgent
from .installment_series_agent import InstallmentSeriesAgent

__all__ = ["ContractInformationAgent", "InstallmentSeriesAgent"]
