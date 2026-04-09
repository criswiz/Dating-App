"""add role column to users

Revision ID: 762296c14907
Revises: 20260408_0001
Create Date: 2026-04-09 12:15:59.323518
"""
from alembic import op
import sqlalchemy as sa



# revision identifiers, used by Alembic.
revision = '762296c14907'
down_revision = '20260408_0001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('role', sa.String(), nullable=False, server_default='user'))


def downgrade() -> None:
    op.drop_column('users', 'role')
