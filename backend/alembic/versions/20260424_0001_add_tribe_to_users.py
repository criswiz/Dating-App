"""add tribe column to users

Revision ID: 20260424_0001
Revises: 762296c14907
Create Date: 2026-04-24 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = '20260424_0001'
down_revision = '20260409_0001'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('tribe', sa.String(), nullable=True))


def downgrade():
    op.drop_column('users', 'tribe')
